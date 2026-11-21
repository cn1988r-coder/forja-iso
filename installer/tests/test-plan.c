#include "../src/plan.h"

#include <gio/gio.h>
#include <glib.h>

#define MIB (1024ULL * 1024ULL)
#define GIB (1024ULL * MIB)

static VenomDisk
make_disk(void)
{
    VenomDisk disk = {
        .path = "/dev/vda",
        .model = "Disco virtual",
        .size_bytes = 32ULL * GIB,
        .read_only = FALSE
    };
    return disk;
}

static void
test_automatic_uefi_plan(void)
{
    VenomDisk disk = make_disk();
    GError *error = NULL;
    VenomInstallPlan *plan = venom_install_plan_automatic(
        &disk, VENOM_FIRMWARE_UEFI, &error);
    VenomPartition *efi;
    VenomPartition *root;

    g_assert_no_error(error);
    g_assert_nonnull(plan);
    g_assert_true(plan->requires_confirmation);
    g_assert_true(plan->mode == VENOM_INSTALL_AUTOMATIC);
    g_assert_cmpuint(plan->partitions->len, ==, 2);

    efi = g_ptr_array_index(plan->partitions, 0);
    root = g_ptr_array_index(plan->partitions, 1);
    g_assert_true(efi->role == VENOM_PARTITION_EFI);
    g_assert_true(efi->filesystem == VENOM_FILESYSTEM_FAT32);
    g_assert_cmpstr(efi->mount_point, ==, "/boot/efi");
    g_assert_true(root->role == VENOM_PARTITION_ROOT);
    g_assert_true(root->filesystem == VENOM_FILESYSTEM_EXT4);
    g_assert_cmpstr(root->mount_point, ==, "/");

    venom_install_plan_free(plan);
}

static void
test_automatic_bios_plan(void)
{
    VenomDisk disk = make_disk();
    GError *error = NULL;
    VenomInstallPlan *plan = venom_install_plan_automatic(
        &disk, VENOM_FIRMWARE_BIOS, &error);
    VenomPartition *bios;

    g_assert_no_error(error);
    g_assert_nonnull(plan);
    g_assert_cmpuint(plan->partitions->len, ==, 2);

    bios = g_ptr_array_index(plan->partitions, 0);
    g_assert_true(bios->role == VENOM_PARTITION_BIOS_GRUB);
    g_assert_true(bios->filesystem == VENOM_FILESYSTEM_NONE);
    g_assert_false(bios->format);

    venom_install_plan_free(plan);
}

static void
test_rejects_read_only_disk(void)
{
    VenomDisk disk = make_disk();
    GError *error = NULL;

    disk.read_only = TRUE;
    g_assert_null(venom_install_plan_automatic(
        &disk, VENOM_FIRMWARE_UEFI, &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_PERMISSION_DENIED);
    g_clear_error(&error);
}

static void
test_rejects_small_disk(void)
{
    VenomDisk disk = make_disk();
    GError *error = NULL;

    disk.size_bytes = 8ULL * GIB;
    g_assert_null(venom_install_plan_automatic(
        &disk, VENOM_FIRMWARE_UEFI, &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_NO_SPACE);
    g_clear_error(&error);
}

static void
test_custom_uefi_plan(void)
{
    VenomDisk disk = make_disk();
    const VenomPartitionInput inputs[] = {
        { VENOM_PARTITION_EFI, 1ULL * GIB },
        { VENOM_PARTITION_ROOT, 20ULL * GIB },
        { VENOM_PARTITION_SWAP, 2ULL * GIB }
    };
    GError *error = NULL;
    VenomInstallPlan *plan = venom_install_plan_custom(
        &disk, VENOM_FIRMWARE_UEFI, inputs, G_N_ELEMENTS(inputs), &error);

    g_assert_no_error(error);
    g_assert_nonnull(plan);
    g_assert_true(plan->mode == VENOM_INSTALL_CUSTOM);
    g_assert_cmpuint(plan->partitions->len, ==, 3);
    venom_install_plan_free(plan);
}

static void
test_custom_rejects_missing_boot_partition(void)
{
    VenomDisk disk = make_disk();
    const VenomPartitionInput inputs[] = {
        { VENOM_PARTITION_ROOT, 20ULL * GIB },
        { VENOM_PARTITION_SWAP, 2ULL * GIB }
    };
    GError *error = NULL;

    g_assert_null(venom_install_plan_custom(
        &disk, VENOM_FIRMWARE_UEFI, inputs, G_N_ELEMENTS(inputs), &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT);
    g_clear_error(&error);
}

static void
test_custom_rejects_unaligned_partition(void)
{
    VenomDisk disk = make_disk();
    const VenomPartitionInput inputs[] = {
        { VENOM_PARTITION_EFI, 1ULL * GIB + 512 },
        { VENOM_PARTITION_ROOT, 20ULL * GIB }
    };
    GError *error = NULL;

    g_assert_null(venom_install_plan_custom(
        &disk, VENOM_FIRMWARE_UEFI, inputs, G_N_ELEMENTS(inputs), &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT);
    g_clear_error(&error);
}

static void
test_custom_rejects_duplicate_root(void)
{
    VenomDisk disk = make_disk();
    const VenomPartitionInput inputs[] = {
        { VENOM_PARTITION_EFI, 1ULL * GIB },
        { VENOM_PARTITION_ROOT, 12ULL * GIB },
        { VENOM_PARTITION_ROOT, 12ULL * GIB }
    };
    GError *error = NULL;

    g_assert_null(venom_install_plan_custom(
        &disk, VENOM_FIRMWARE_UEFI, inputs, G_N_ELEMENTS(inputs), &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT);
    g_clear_error(&error);
}

static void
test_custom_rejects_over_capacity(void)
{
    VenomDisk disk = make_disk();
    const VenomPartitionInput inputs[] = {
        { VENOM_PARTITION_EFI, 1ULL * GIB },
        { VENOM_PARTITION_ROOT, 31ULL * GIB }
    };
    GError *error = NULL;

    g_assert_null(venom_install_plan_custom(
        &disk, VENOM_FIRMWARE_UEFI, inputs, G_N_ELEMENTS(inputs), &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_NO_SPACE);
    g_clear_error(&error);
}

static void
test_rejects_unsafe_device_path(void)
{
    VenomDisk disk = make_disk();
    GError *error = NULL;

    disk.path = "/dev/../sda";
    g_assert_null(venom_install_plan_automatic(
        &disk, VENOM_FIRMWARE_UEFI, &error));
    g_assert_error(error, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT);
    g_clear_error(&error);
}

int
main(int argc, char **argv)
{
    g_test_init(&argc, &argv, NULL);
    g_test_add_func("/plano/automatico-uefi", test_automatic_uefi_plan);
    g_test_add_func("/plano/automatico-bios", test_automatic_bios_plan);
    g_test_add_func("/plano/rejeita-disco-somente-leitura", test_rejects_read_only_disk);
    g_test_add_func("/plano/rejeita-disco-pequeno", test_rejects_small_disk);
    g_test_add_func("/plano/personalizado-uefi", test_custom_uefi_plan);
    g_test_add_func("/plano/rejeita-boot-ausente", test_custom_rejects_missing_boot_partition);
    g_test_add_func("/plano/rejeita-tamanho-desalinhado", test_custom_rejects_unaligned_partition);
    g_test_add_func("/plano/rejeita-raiz-duplicada", test_custom_rejects_duplicate_root);
    g_test_add_func("/plano/rejeita-excesso-de-capacidade", test_custom_rejects_over_capacity);
    g_test_add_func("/plano/rejeita-caminho-inseguro", test_rejects_unsafe_device_path);
    return g_test_run();
}
