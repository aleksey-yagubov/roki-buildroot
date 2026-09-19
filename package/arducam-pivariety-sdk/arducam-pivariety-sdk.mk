################################################################################
#
# arducam-pivariety-sdk
#
################################################################################

ARDUCAM_PIVARIETY_SDK_VERSION = 1.0.7
ARDUCAM_PIVARIETY_SDK_SITE = file://$(BR2_EXTERNAL_ROKI_PATH)/package/arducam-pivariety-sdk/files
ARDUCAM_PIVARIETY_SDK_SOURCE = arducam-pivariety-sdk-dev_$(ARDUCAM_PIVARIETY_SDK_VERSION)_arm64.deb
ARDUCAM_PIVARIETY_SDK_LICENSE = Proprietary
ARDUCAM_PIVARIETY_SDK_INSTALL_STAGING = YES

define ARDUCAM_PIVARIETY_SDK_EXTRACT_CMDS
	$(Q)mkdir -p $(@D)
	$(Q)cd $(@D) && $(HOSTAR) x $(ARDUCAM_PIVARIETY_SDK_DL_DIR)/$(ARDUCAM_PIVARIETY_SDK_SOURCE)
	$(Q)$(TAR) -xJf $(@D)/data.tar.xz -C $(@D)
endef

define ARDUCAM_PIVARIETY_SDK_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/usr/include/arducam/arducam_pivariety.hpp \
		$(STAGING_DIR)/usr/include/arducam/arducam_pivariety.hpp
	$(INSTALL) -D -m 0644 $(@D)/usr/include/arducam/tuning_data_template.hpp \
		$(STAGING_DIR)/usr/include/arducam/tuning_data_template.hpp
	$(INSTALL) -D -m 0644 $(@D)/usr/lib/libarducam_pivariety.so.1.0.7 \
		$(STAGING_DIR)/usr/lib/libarducam_pivariety.so.1.0.7
	ln -sf libarducam_pivariety.so.1.0.7 $(STAGING_DIR)/usr/lib/libarducam_pivariety.so
	$(INSTALL) -D -m 0644 $(@D)/usr/lib/pkgconfig/arducam_pivariety.pc \
		$(STAGING_DIR)/usr/lib/pkgconfig/arducam_pivariety.pc
endef

define ARDUCAM_PIVARIETY_SDK_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/usr/lib/libarducam_pivariety.so.1.0.7 \
		$(TARGET_DIR)/usr/lib/libarducam_pivariety.so.1.0.7
	ln -sf libarducam_pivariety.so.1.0.7 $(TARGET_DIR)/usr/lib/libarducam_pivariety.so
endef

$(eval $(generic-package))
