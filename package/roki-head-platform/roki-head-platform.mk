################################################################################
#
# roki-head-platform
#
################################################################################

define ROKI_HEAD_PLATFORM_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/bin $(TARGET_DIR)/usr/lib/roki
	$(INSTALL) -m 0644 $(ROKI_HEAD_PLATFORM_PKGDIR)/files/roki-display.py \
		$(TARGET_DIR)/usr/bin/roki-display.py
	$(INSTALL) -m 0644 $(ROKI_HEAD_PLATFORM_PKGDIR)/files/roki_display_font.py \
		$(TARGET_DIR)/usr/lib/roki/roki_display_font.py
	$(INSTALL) -m 0644 $(ROKI_HEAD_PLATFORM_PKGDIR)/files/roki-buttons.py \
		$(TARGET_DIR)/usr/bin/roki-buttons.py
endef

$(eval $(generic-package))
