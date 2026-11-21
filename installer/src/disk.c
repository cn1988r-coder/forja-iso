#include "disk.h"

#include <gio/gio.h>
#include <json-glib/json-glib.h>
#include <string.h>

void
venom_disk_free(gpointer data)
{
    VenomDisk *disk = data;

    if (disk == NULL) {
        return;
    }

    g_free(disk->path);
    g_free(disk->model);
    g_free(disk);
}

GPtrArray *
venom_disk_list_from_json(const gchar *json, GError **error)
{
    JsonParser *parser;
    JsonNode *root;
    JsonObject *root_object;
    JsonNode *devices_node;
    JsonArray *devices;
    GPtrArray *result;

    g_return_val_if_fail(json != NULL, NULL);

    parser = json_parser_new();
    if (!json_parser_load_from_data(parser, json, -1, error)) {
        g_object_unref(parser);
        return NULL;
    }

    root = json_parser_get_root(parser);
    if (root == NULL || !JSON_NODE_HOLDS_OBJECT(root)) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_DATA,
                            "A resposta de lsblk não contém um objeto JSON.");
        g_object_unref(parser);
        return NULL;
    }

    root_object = json_node_get_object(root);
    devices_node = json_object_get_member(root_object, "blockdevices");
    if (devices_node == NULL || !JSON_NODE_HOLDS_ARRAY(devices_node)) {
        g_set_error_literal(error, G_IO_ERROR, G_IO_ERROR_INVALID_DATA,
                            "A resposta de lsblk não contém a lista de dispositivos.");
        g_object_unref(parser);
        return NULL;
    }

    devices = json_node_get_array(devices_node);
    result = g_ptr_array_new_with_free_func(venom_disk_free);

    for (guint i = 0; i < json_array_get_length(devices); i++) {
        JsonObject *item = json_array_get_object_element(devices, i);
        const gchar *type;
        const gchar *path;
        const gchar *model;
        gint64 size_bytes = 0;
        gint64 read_only = 0;
        VenomDisk *disk;

        if (item == NULL || !json_object_has_member(item, "type")) {
            continue;
        }

        type = json_object_get_string_member(item, "type");
        if (g_strcmp0(type, "disk") != 0 ||
            !json_object_has_member(item, "path")) {
            continue;
        }

        path = json_object_get_string_member(item, "path");
        if (path == NULL || !g_str_has_prefix(path, "/dev/")) {
            continue;
        }

        model = json_object_has_member(item, "model")
                    ? json_object_get_string_member(item, "model")
                    : NULL;
        if (json_object_has_member(item, "size")) {
            size_bytes = json_object_get_int_member(item, "size");
        }
        if (json_object_has_member(item, "ro")) {
            read_only = json_object_get_int_member(item, "ro");
        }

        disk = g_new0(VenomDisk, 1);
        disk->path = g_strdup(path);
        disk->model = g_strdup(model != NULL && *model != '\0'
                                   ? model
                                   : "Modelo não informado");
        disk->size_bytes = size_bytes > 0 ? (guint64) size_bytes : 0;
        disk->read_only = read_only != 0;
        g_ptr_array_add(result, disk);
    }

    g_object_unref(parser);
    return result;
}

GPtrArray *
venom_disk_enumerate(GError **error)
{
    const gchar *argv[] = {
        "lsblk",
        "--json",
        "--bytes",
        "--nodeps",
        "--output",
        "PATH,SIZE,MODEL,TYPE,RO",
        NULL
    };
    GSubprocess *process;
    gchar *stdout_text = NULL;
    gchar *stderr_text = NULL;
    GPtrArray *result;

    process = g_subprocess_newv(
        argv,
        G_SUBPROCESS_FLAGS_STDOUT_PIPE | G_SUBPROCESS_FLAGS_STDERR_PIPE,
        error
    );
    if (process == NULL) {
        return NULL;
    }

    if (!g_subprocess_communicate_utf8(
            process, NULL, NULL, &stdout_text, &stderr_text, error)) {
        g_clear_object(&process);
        g_free(stdout_text);
        g_free(stderr_text);
        return NULL;
    }

    if (!g_subprocess_get_successful(process)) {
        g_set_error(error, G_IO_ERROR, G_IO_ERROR_FAILED,
                    "Não foi possível consultar os discos: %s",
                    stderr_text != NULL ? stderr_text : "lsblk retornou erro.");
        g_clear_object(&process);
        g_free(stdout_text);
        g_free(stderr_text);
        return NULL;
    }

    result = venom_disk_list_from_json(stdout_text, error);
    g_clear_object(&process);
    g_free(stdout_text);
    g_free(stderr_text);
    return result;
}
