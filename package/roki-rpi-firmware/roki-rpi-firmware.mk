################################################################################
#
# roki-rpi-firmware
#
################################################################################

ROKI_RPI_FIRMWARE_VERSION = 2768f6105ab38838934f9cfb3c5e5c16326d8a01
# The CM4 EEPROM loads start4.elf itself; no bootcode4.bin is needed.
# Avoid downloading the complete firmware repository when only these two
# boot files are placed on the FAT partition.
ROKI_RPI_FIRMWARE_SOURCE =
ROKI_RPI_FIRMWARE_START4 = \
	https://raw.githubusercontent.com/raspberrypi/firmware/$(ROKI_RPI_FIRMWARE_VERSION)/boot/start4.elf
ROKI_RPI_FIRMWARE_FIXUP4 = \
	https://raw.githubusercontent.com/raspberrypi/firmware/$(ROKI_RPI_FIRMWARE_VERSION)/boot/fixup4.dat
ROKI_RPI_FIRMWARE_EXTRA_DOWNLOADS = \
	$(ROKI_RPI_FIRMWARE_START4) \
	$(ROKI_RPI_FIRMWARE_FIXUP4)
ROKI_RPI_FIRMWARE_LICENSE = BSD-3-Clause
ROKI_RPI_FIRMWARE_INSTALL_IMAGES = YES

ROKI_RPI_FIRMWARE_BOOT_DIR = $(BINARIES_DIR)/roki-boot
define ROKI_RPI_FIRMWARE_EXTRACT_CMDS
	$(INSTALL) -D -m 0644 \
		$(ROKI_RPI_FIRMWARE_DL_DIR)/$(notdir $(ROKI_RPI_FIRMWARE_START4)) \
		$(@D)/start4.elf
	$(INSTALL) -D -m 0644 \
		$(ROKI_RPI_FIRMWARE_DL_DIR)/$(notdir $(ROKI_RPI_FIRMWARE_FIXUP4)) \
		$(@D)/fixup4.dat
endef

define ROKI_RPI_FIRMWARE_INSTALL_IMAGES_CMDS
	mkdir -p $(ROKI_RPI_FIRMWARE_BOOT_DIR)
	$(INSTALL) -m 0644 $(@D)/start4.elf \
		$(ROKI_RPI_FIRMWARE_BOOT_DIR)/start4.elf
	$(INSTALL) -m 0644 $(@D)/fixup4.dat \
		$(ROKI_RPI_FIRMWARE_BOOT_DIR)/fixup4.dat
	$(INSTALL) -m 0644 $(ROKI_RPI_FIRMWARE_PKGDIR)/../../board/roki-cm4/config.txt \
		$(ROKI_RPI_FIRMWARE_BOOT_DIR)/config.txt
	$(INSTALL) -m 0644 $(ROKI_RPI_FIRMWARE_PKGDIR)/../../board/roki-cm4/cmdline.txt \
		$(ROKI_RPI_FIRMWARE_BOOT_DIR)/cmdline.txt
	$(INSTALL) -m 0644 $(ROKI_RPI_FIRMWARE_PKGDIR)/../../board/roki-cm4/cmdline-debug.txt \
		$(ROKI_RPI_FIRMWARE_BOOT_DIR)/cmdline-debug.txt
endef

$(eval $(generic-package))
