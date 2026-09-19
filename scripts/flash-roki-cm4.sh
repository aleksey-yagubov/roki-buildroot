#!/usr/bin/env bash
# Flash a Roki CM4 image and grow its root partition to the production 600 MiB.
set -Eeuo pipefail

ROOTFS_SIZE_MIB=600

usage() {
    cat <<'EOF'
Usage: sudo flash-roki-cm4.sh [--yes] <whole-block-device> <roki-cm4.img>

Example:
  sudo ./scripts/flash-roki-cm4.sh /dev/sdX output/images/roki-cm4.img

The whole target device is erased. The script writes the image, expands
partition 2 to 600 MiB, checks its ext4 filesystem, and runs resize2fs.
EOF
}

assume_yes=false
if [[ ${1:-} == --yes ]]; then
    assume_yes=true
    shift
fi

if [[ $# -ne 2 ]]; then
    usage >&2
    exit 2
fi

device=$(readlink -f "$1")
image=$(readlink -f "$2")

[[ $EUID -eq 0 ]] || { echo 'Run as root.' >&2; exit 1; }
[[ -b $device ]] || { echo "Not a block device: $device" >&2; exit 1; }
[[ -f $image ]] || { echo "Image not found: $image" >&2; exit 1; }
[[ $(lsblk -ndo TYPE "$device") == disk ]] || {
    echo "Pass the whole device, not a partition: $device" >&2
    exit 1
}

if [[ $device =~ [0-9]$ ]]; then
    root_partition=${device}p2
else
    root_partition=${device}2
fi

if lsblk -nrpo MOUNTPOINT "$device" | grep -q '[^[:space:]]'; then
    echo "Unmount all partitions of $device before flashing." >&2
    exit 1
fi

if ! $assume_yes; then
    echo "This erases $device and all of its partitions."
    read -r -p "Type '$device' to continue: " answer
    [[ $answer == "$device" ]] || { echo 'Aborted.' >&2; exit 1; }
fi

for command in dd sfdisk blockdev e2fsck resize2fs awk lsblk; do
    command -v "$command" >/dev/null || {
        echo "Required command not found: $command" >&2
        exit 1
    }
done

echo "Writing $image to $device..."
dd if="$image" of="$device" bs=16M iflag=fullblock oflag=direct conv=fsync status=progress

sector_size=$(blockdev --getss "$device")
root_sectors=$((ROOTFS_SIZE_MIB * 1024 * 1024 / sector_size))
disk_sectors=$(blockdev --getsz "$device")
table=$(sfdisk -d "$device")
root_line=$(awk -v part="$root_partition" '$1 == part { print; exit }' <<<"$table")

[[ -n $root_line ]] || { echo "Cannot find $root_partition in partition table." >&2; exit 1; }
[[ $root_line =~ start=[[:space:]]*([0-9]+) ]] || {
    echo "Cannot read start sector for $root_partition." >&2
    exit 1
}
root_start=${BASH_REMATCH[1]}
(( root_start + root_sectors <= disk_sectors )) || {
    echo "$device is too small for a ${ROOTFS_SIZE_MIB} MiB root partition." >&2
    exit 1
}

new_table=$(awk -v part="$root_partition" -v size="$root_sectors" '
    $1 == part { sub(/size=[[:space:]]*[0-9]+/, "size=" size) }
    { print }
' <<<"$table")

echo "Expanding $root_partition to ${ROOTFS_SIZE_MIB} MiB..."
printf '%s\n' "$new_table" | sfdisk --force "$device"
sync

for _ in {1..20}; do
    [[ -b $root_partition ]] && break
    sleep 0.1
done
[[ -b $root_partition ]] || { echo "Partition node did not appear: $root_partition" >&2; exit 1; }

set +e
e2fsck -fy "$root_partition"
fsck_status=$?
set -e
(( fsck_status <= 1 )) || { echo "e2fsck failed with status $fsck_status." >&2; exit "$fsck_status"; }

resize2fs "$root_partition"
sync
echo "Done: $root_partition is now ${ROOTFS_SIZE_MIB} MiB."
