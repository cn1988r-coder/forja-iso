#include "../src/disk.h"

#include <glib.h>

static const gchar fixture[] =
    "{"
    "\"blockdevices\":["
    "{\"path\":\"/dev/sda\",\"size\":512110190592,"
    "\"model\":\"SSD de teste\",\"type\":\"disk\",\"ro\":0},"
    "{\"path\":\"/dev/sda1\",\"size\":512000000000,"
    "\"model\":null,\"type\":\"part\",\"ro\":0},"
    "{\"path\":\"/dev/sdb\",\"size\":64000000000,"
    "\"model\":\"Mídia somente leitura\",\"type\":\"disk\",\"ro\":1}"
    "]"
    "}";

static void
test_filters_partitions_and_keeps_read_only_state(void)
{
    GError *error = NULL;
    GPtrArray *disks = venom_disk_list_from_json(fixture, &error);
    VenomDisk *first;
    VenomDisk *second;

    g_assert_no_error(error);
    g_assert_nonnull(disks);
    g_assert_cmpuint(disks->len, ==, 2);

    first = g_ptr_array_index(disks, 0);
    second = g_ptr_array_index(disks, 1);

    g_assert_cmpstr(first->path, ==, "/dev/sda");
    g_assert_cmpstr(first->model, ==, "SSD de teste");
    g_assert_cmpuint(first->size_bytes, ==, 512110190592ULL);
    g_assert_false(first->read_only);

    g_assert_cmpstr(second->path, ==, "/dev/sdb");
    g_assert_true(second->read_only);

    g_ptr_array_unref(disks);
}

static void
test_rejects_invalid_json(void)
{
    GError *error = NULL;
    GPtrArray *disks = venom_disk_list_from_json("{ inválido", &error);

    g_assert_null(disks);
    g_assert_nonnull(error);
    g_clear_error(&error);
}

static void
test_rejects_missing_blockdevices(void)
{
    GError *error = NULL;
    GPtrArray *disks = venom_disk_list_from_json("{\"devices\":[]}", &error);

    g_assert_null(disks);
    g_assert_nonnull(error);
    g_clear_error(&error);
}

int
main(int argc, char **argv)
{
    g_test_init(&argc, &argv, NULL);
    g_test_add_func("/discos/filtra-particoes-e-preserva-leitura",
                    test_filters_partitions_and_keeps_read_only_state);
    g_test_add_func("/discos/rejeita-json-invalido", test_rejects_invalid_json);
    g_test_add_func("/discos/rejeita-lista-ausente",
                    test_rejects_missing_blockdevices);
    return g_test_run();
}
