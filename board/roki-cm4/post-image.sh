#!/bin/sh

set -eu

BINARIES_DIR=$1
BOARD_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BOOT_DIR="${BINARIES_DIR}/roki-boot"

test -f "${BOOT_DIR}/config.txt"
test -f "${BOOT_DIR}/cmdline.txt"
test -f "${BOOT_DIR}/cmdline-debug.txt"
test -f "${BOOT_DIR}/start4.elf"
test -f "${BOOT_DIR}/fixup4.dat"
test -f "${BINARIES_DIR}/Image"
test -f "${BINARIES_DIR}/bcm2711-roki-head.dtb"
test -f "${BINARIES_DIR}/rootfs.ext4"

# Raspberry Pi firmware expects this filename; Buildroot emits the normal Image.
install -m 0644 "${BINARIES_DIR}/Image" "${BOOT_DIR}/kernel8.img"
install -m 0644 "${BINARIES_DIR}/bcm2711-roki-head.dtb" \
	"${BOOT_DIR}/bcm2711-roki-head.dtb"

support/scripts/genimage.sh -c "${BOARD_DIR}/genimage.cfg"
