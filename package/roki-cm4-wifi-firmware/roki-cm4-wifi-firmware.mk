################################################################################
#
# roki-cm4-wifi-firmware
#
################################################################################

ROKI_CM4_WIFI_FIRMWARE_VERSION = 2026.09.03
ROKI_CM4_WIFI_FIRMWARE_SITE = $(BR2_KERNEL_MIRROR)/software/network/wireless-regdb
ROKI_CM4_WIFI_FIRMWARE_SOURCE = wireless-regdb-$(ROKI_CM4_WIFI_FIRMWARE_VERSION).tar.xz
ROKI_CM4_WIFI_FIRMWARE_LICENSE = ISC and proprietary
ROKI_CM4_WIFI_FIRMWARE_LICENSE_FILES = LICENSE
ROKI_CM4_WIFI_FIRMWARE_INSTALL_TARGET = NO

# Do not clone linux-firmware. These are the only blobs used by the CM4.
ROKI_CM4_WIFI_FIRMWARE_EXTRA_DOWNLOADS = \
	https://raw.githubusercontent.com/Infineon/ifx-linux-firmware/d24c95cce5e77b04736972ba05ccd06da6cc377f/firmware/cyfmac43455-sdio.bin \
	https://raw.githubusercontent.com/Infineon/ifx-linux-firmware/d24c95cce5e77b04736972ba05ccd06da6cc377f/firmware/cyfmac43455-sdio.clm_blob \
	https://gitlab.com/kernel-firmware/linux-firmware/-/raw/2f2bf38a3d030a083d8b2b1fea2aa0e9b29a48bd/brcm/brcmfmac43455-sdio.raspberrypi,4-model-b.txt

define ROKI_CM4_WIFI_FIRMWARE_EXTRACT_CMDS
	$(TAR) -xJf $(ROKI_CM4_WIFI_FIRMWARE_DL_DIR)/$(ROKI_CM4_WIFI_FIRMWARE_SOURCE) -C $(@D) \
		--strip-components=1 wireless-regdb-$(ROKI_CM4_WIFI_FIRMWARE_VERSION)/regulatory.db
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DL_DIR)/cyfmac43455-sdio.bin \
		$(@D)/brcm/brcmfmac43455-sdio.bin
	# brcmfmac first requests the CM4 board-specific filename, then falls back
	# to the generic blob. They intentionally contain the same firmware.
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DL_DIR)/cyfmac43455-sdio.bin \
		$(@D)/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.bin
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DL_DIR)/cyfmac43455-sdio.clm_blob \
		$(@D)/brcm/brcmfmac43455-sdio.clm_blob
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DL_DIR)/brcmfmac43455-sdio.raspberrypi,4-model-b.txt \
		$(@D)/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt
endef

define ROKI_CM4_WIFI_FIRMWARE_COPY_TO_KERNEL
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/regulatory.db \
		$(LINUX_DIR)/roki-cm4-firmware/regulatory.db
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.bin \
		$(LINUX_DIR)/roki-cm4-firmware/brcm/brcmfmac43455-sdio.bin
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.bin \
		$(LINUX_DIR)/roki-cm4-firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.bin
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.clm_blob \
		$(LINUX_DIR)/roki-cm4-firmware/brcm/brcmfmac43455-sdio.clm_blob
	$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt \
		$(LINUX_DIR)/roki-cm4-firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt
	# A manually configured out-of-tree Linux build has a generated Makefile
	# pointing at a separate srctree. Buildroot's normal in-tree build skips it.
	kernel_makefile=$$(sed -n 's|^include ||p' $(LINUX_DIR)/Makefile); \
	if [ -f "$$kernel_makefile" ]; then \
		kernel_src=$$(dirname "$$kernel_makefile"); \
		$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/regulatory.db \
			"$$kernel_src/roki-cm4-firmware/regulatory.db"; \
		$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.bin \
			"$$kernel_src/roki-cm4-firmware/brcm/brcmfmac43455-sdio.bin"; \
		$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.bin \
			"$$kernel_src/roki-cm4-firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.bin"; \
		$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.clm_blob \
			"$$kernel_src/roki-cm4-firmware/brcm/brcmfmac43455-sdio.clm_blob"; \
		$(INSTALL) -D -m 0644 $(ROKI_CM4_WIFI_FIRMWARE_DIR)/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt \
			"$$kernel_src/roki-cm4-firmware/brcm/brcmfmac43455-sdio.raspberrypi,4-compute-module.txt"; \
	fi
endef

LINUX_DEPENDENCIES += $(if $(BR2_PACKAGE_ROKI_CM4_WIFI_FIRMWARE),roki-cm4-wifi-firmware)
LINUX_PRE_BUILD_HOOKS += ROKI_CM4_WIFI_FIRMWARE_COPY_TO_KERNEL

$(eval $(generic-package))
