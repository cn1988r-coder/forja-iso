#include "plan.h"

#include <gio/gio.h>
#include <string.h>

#define MIB (1024ULL * 1024ULL)
#define GIB (1024ULL * MIB)
#define MINIMUM_DISK_SIZE (20ULL * GIB)
#define MINIMUM_ROOT_SIZE (12ULL * GIB)
#define MINIMUM_SWAP_SIZE (1ULL * GIB)
#define MINIMUM_EFI_SIZE (512ULL * MIB)
#define MAXIMUM_EFI_SIZE (2ULL * GIB)
#define RESERVED_TAIL_SIZE (4ULL * MIB)

static gboolean
valid_device_path(const gchar *path)
{
    gchar **components;
    gboolean valid = TRUE;

    if (path == NULL || !g_str_has_prefix(path, "/dev/") ||
        path[5] == '\0') {
        return FALSE;
    }

    components = g_strsplit(path + 5, "/", -1);
    for (gsize i = 0; components[i] != NULL && valid; i++) {
        const gchar *component = components[i];

        if (*component == '\0' || g_str_equal(component, ".") ||
            g_str_equal(component, "..")) {
            valid = FALSE;
            break;
        }

        for (const gchar *cursor = component; *cursor != '\0'; cursor++) {
            if (!g_ascii_isalnum(*cursor) && *cursor != '_' &&
                *cursor != '-' && *cursor != '.' && *cursor != ':') {
                valid = FALSE;
                break;
            }
        }
    }

    g_strfreev(components);
    return valid;
}

static gboolean
validate_disk(const VenomDisk *disk, GError **error)
{
    if (disk == NULL || !valid_device_path(disk->path)) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "O dispositivo selecionado não é um caminho de disco válido.");
        return FALSE;
    }

    if (disk->read_only) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_PERMISSION_DENIED,
                            "O disco selecionado está somente para leitura.");
        return FALSE;
    }

    if (disk->size_bytes < MINIMUM_DISK_SIZE) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_NO_SPACE,
                            "O disco precisa ter pelo menos 20 GiB.");
        return FALSE;
    }

    return TRUE;
}

static void
partition_free(gpointer data)
{
    VenomPartition *partition = data;

    if (partition == NULL) {
        return;
    }

    g_free(partition->mount_point);
    g_free(partition);
}

void
venom_install_plan_free(gpointer data)
{
    VenomInstallPlan *plan = data;

    if (plan == NULL) {
        return;
    }

    g_free(plan->disk_path);
    g_free(plan->partition_table);
    g_clear_pointer(&plan->partitions, g_ptr_array_unref);
    g_free(plan);
}

static VenomInstallPlan *
plan_new(const VenomDisk *disk,
         VenomFirmwareMode firmware,
         VenomInstallMode mode)
{
    VenomInstallPlan *plan = g_new0(VenomInstallPlan, 1);

    plan->disk_path = g_strdup(disk->path);
    plan->disk_size_bytes = disk->size_bytes;
    plan->firmware = firmware;
    plan->mode = mode;
    plan->partition_table = g_strdup("GPT");
    plan->partitions = g_ptr_array_new_with_free_func(partition_free);
    plan->requires_confirmation = TRUE;
    return plan;
}

static gboolean
add_partition(VenomInstallPlan *plan,
              VenomPartitionRole role,
              guint64 size_bytes,
              GError **error)
{
    VenomPartition *partition = g_new0(VenomPartition, 1);

    if (size_bytes == 0 || size_bytes % MIB != 0) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "Todos os tamanhos devem ser múltiplos de 1 MiB.");
        g_free(partition);
        return FALSE;
    }

    partition->role = role;
    partition->size_bytes = size_bytes;
    partition->format = TRUE;

    switch (role) {
    case VENOM_PARTITION_EFI:
        if (size_bytes < MINIMUM_EFI_SIZE ||
            size_bytes > MAXIMUM_EFI_SIZE) {
            g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                                "A partição EFI deve ter entre 512 MiB e 2 GiB.");
            g_free(partition);
            return FALSE;
        }
        partition->filesystem = VENOM_FILESYSTEM_FAT32;
        partition->mount_point = g_strdup("/boot/efi");
        break;
    case VENOM_PARTITION_BIOS_GRUB:
        if (size_bytes < MIB || size_bytes > 16ULL * MIB) {
            g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                                "A partição BIOS de inicialização deve ter entre 1 e 16 MiB.");
            g_free(partition);
            return FALSE;
        }
        partition->filesystem = VENOM_FILESYSTEM_NONE;
        partition->format = FALSE;
        break;
    case VENOM_PARTITION_ROOT:
        if (size_bytes < MINIMUM_ROOT_SIZE) {
            g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_NO_SPACE,
                                "A partição raiz precisa ter pelo menos 12 GiB.");
            g_free(partition);
            return FALSE;
        }
        partition->filesystem = VENOM_FILESYSTEM_EXT4;
        partition->mount_point = g_strdup("/");
        break;
    case VENOM_PARTITION_SWAP:
        if (size_bytes < MINIMUM_SWAP_SIZE) {
            g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                                "A partição de troca precisa ter pelo menos 1 GiB.");
            g_free(partition);
            return FALSE;
        }
        partition->filesystem = VENOM_FILESYSTEM_SWAP;
        break;
    default:
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "O plano contém uma função de partição desconhecida.");
        g_free(partition);
        return FALSE;
    }

    g_ptr_array_add(plan->partitions, partition);
    return TRUE;
}

static gboolean
validate_partition_layout(VenomInstallPlan *plan, GError **error)
{
    guint roots = 0;
    guint efis = 0;
    guint bios_boot = 0;
    guint swaps = 0;
    guint64 total = 0;
    guint64 usable = plan->disk_size_bytes - RESERVED_TAIL_SIZE;

    for (guint i = 0; i < plan->partitions->len; i++) {
        VenomPartition *partition = g_ptr_array_index(plan->partitions, i);

        switch (partition->role) {
        case VENOM_PARTITION_ROOT:
            roots++;
            break;
        case VENOM_PARTITION_EFI:
            efis++;
            break;
        case VENOM_PARTITION_BIOS_GRUB:
            bios_boot++;
            break;
        case VENOM_PARTITION_SWAP:
            swaps++;
            break;
        }

        if (total > usable || partition->size_bytes > usable - total) {
            g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_NO_SPACE,
                                "O tamanho total das partições excede o espaço seguro do disco.");
            return FALSE;
        }
        total += partition->size_bytes;
    }

    if (roots != 1 || efis > 1 || bios_boot > 1 || swaps > 1) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "O plano deve conter uma raiz e no máximo uma partição EFI, BIOS ou swap.");
        return FALSE;
    }

    if (plan->firmware == VENOM_FIRMWARE_UEFI &&
        (efis != 1 || bios_boot != 0)) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "Inicialização UEFI exige uma partição EFI e não usa partição BIOS.");
        return FALSE;
    }

    if (plan->firmware == VENOM_FIRMWARE_BIOS &&
        (bios_boot != 1 || efis != 0)) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "Inicialização BIOS exige uma partição BIOS e não usa partição EFI.");
        return FALSE;
    }

    return TRUE;
}

VenomInstallPlan *
venom_install_plan_custom(const VenomDisk *disk,
                          VenomFirmwareMode firmware,
                          const VenomPartitionInput *partitions,
                          gsize partition_count,
                          GError **error)
{
    VenomInstallPlan *plan;

    if (!validate_disk(disk, error)) {
        return NULL;
    }

    if (firmware != VENOM_FIRMWARE_UEFI &&
        firmware != VENOM_FIRMWARE_BIOS) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "Modo de inicialização desconhecido.");
        return NULL;
    }

    if (partitions == NULL || partition_count < 2 || partition_count > 4) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "O plano personalizado deve conter de 2 a 4 partições.");
        return NULL;
    }

    plan = plan_new(disk, firmware, VENOM_INSTALL_CUSTOM);
    for (gsize i = 0; i < partition_count; i++) {
        if (!add_partition(plan, partitions[i].role,
                           partitions[i].size_bytes, error)) {
            venom_install_plan_free(plan);
            return NULL;
        }
    }

    if (!validate_partition_layout(plan, error)) {
        venom_install_plan_free(plan);
        return NULL;
    }

    return plan;
}

VenomInstallPlan *
venom_install_plan_automatic(const VenomDisk *disk,
                             VenomFirmwareMode firmware,
                             GError **error)
{
    VenomPartitionInput inputs[2];
    guint64 disk_mib;
    guint64 boot_mib;

    if (!validate_disk(disk, error)) {
        return NULL;
    }

    if (firmware != VENOM_FIRMWARE_UEFI &&
        firmware != VENOM_FIRMWARE_BIOS) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
                            "Modo de inicialização desconhecido.");
        return NULL;
    }

    disk_mib = disk->size_bytes / MIB;
    boot_mib = firmware == VENOM_FIRMWARE_UEFI ? 1024 : 2;

    if (disk_mib <= boot_mib + RESERVED_TAIL_SIZE / MIB) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_NO_SPACE,
                            "O disco não possui espaço para o plano automático.");
        return NULL;
    }

    inputs[0].role = firmware == VENOM_FIRMWARE_UEFI
                         ? VENOM_PARTITION_EFI
                         : VENOM_PARTITION_BIOS_GRUB;
    inputs[0].size_bytes = boot_mib * MIB;
    inputs[1].role = VENOM_PARTITION_ROOT;
    inputs[1].size_bytes =
        (disk_mib - boot_mib - RESERVED_TAIL_SIZE / MIB) * MIB;

    VenomInstallPlan *plan = venom_install_plan_custom(
        disk, firmware, inputs, G_N_ELEMENTS(inputs), error);

    if (plan != NULL) {
        plan->mode = VENOM_INSTALL_AUTOMATIC;
    }
    return plan;
}
