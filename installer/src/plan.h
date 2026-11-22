#pragma once

#include <glib.h>

#include "disk.h"

typedef enum {
    VENOM_FIRMWARE_UEFI,
    VENOM_FIRMWARE_BIOS
} VenomFirmwareMode;

typedef enum {
    VENOM_INSTALL_AUTOMATIC,
    VENOM_INSTALL_CUSTOM
} VenomInstallMode;

typedef enum {
    VENOM_PARTITION_EFI,
    VENOM_PARTITION_BIOS_GRUB,
    VENOM_PARTITION_ROOT,
    VENOM_PARTITION_SWAP
} VenomPartitionRole;

typedef enum {
    VENOM_FILESYSTEM_NONE,
    VENOM_FILESYSTEM_FAT32,
    VENOM_FILESYSTEM_BTRFS,
    VENOM_FILESYSTEM_SWAP
} VenomFilesystem;

typedef struct {
    VenomPartitionRole role;
    guint64 size_bytes;
} VenomPartitionInput;

typedef struct {
    VenomPartitionRole role;
    VenomFilesystem filesystem;
    guint64 size_bytes;
    gchar *mount_point;
    gboolean format;
} VenomPartition;

typedef struct {
    gchar *disk_path;
    guint64 disk_size_bytes;
    VenomFirmwareMode firmware;
    VenomInstallMode mode;
    gchar *partition_table;
    GPtrArray *partitions;
    gboolean requires_confirmation;
    gchar *root_subvolume;
    gchar *home_subvolume;
    gboolean snapshot_support;
} VenomInstallPlan;

/*
 * These functions only build and validate an installation proposal.
 * They never partition, format, mount, or write to a block device.
 */
VenomInstallPlan *venom_install_plan_automatic(
    const VenomDisk *disk,
    VenomFirmwareMode firmware,
    GError **error
);

VenomInstallPlan *venom_install_plan_custom(
    const VenomDisk *disk,
    VenomFirmwareMode firmware,
    const VenomPartitionInput *partitions,
    gsize partition_count,
    GError **error
);

void venom_install_plan_free(gpointer data);
