#pragma once

#include <glib.h>

typedef struct {
    gchar *path;
    gchar *model;
    guint64 size_bytes;
    gboolean read_only;
} VenomDisk;

GPtrArray *venom_disk_list_from_json(const gchar *json, GError **error);
GPtrArray *venom_disk_enumerate(GError **error);
void venom_disk_free(gpointer data);
