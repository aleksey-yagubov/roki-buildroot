################################################################################
#
# roki-dinit-rc
#
################################################################################

ROKI_DINIT_RC_DEPENDENCIES = dinit
ROKI_DINIT_RC_SERVICE_FILES = $(filter-out \
	$(ROKI_DINIT_RC_PKGDIR)/files/etc/dinit.d/net-lo \
	$(ROKI_DINIT_RC_PKGDIR)/files/etc/dinit.d/recovery \
	$(ROKI_DINIT_RC_PKGDIR)/files/etc/dinit.d/serial-debug-shell, \
	$(wildcard $(ROKI_DINIT_RC_PKGDIR)/files/etc/dinit.d/*))

define ROKI_DINIT_RC_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/boot $(TARGET_DIR)/etc/dinit.d \
		$(TARGET_DIR)/etc/iwd \
		$(TARGET_DIR)/etc/profile.d \
		$(TARGET_DIR)/etc/ssh $(TARGET_DIR)/usr/lib/dinit \
		$(TARGET_DIR)/usr/bin $(TARGET_DIR)/usr/share/terminfo/f $(TARGET_DIR)/var/log
	ln -snf ../run $(TARGET_DIR)/var/run
	rm -f $(TARGET_DIR)/etc/dinit.d/net-lo \
		$(TARGET_DIR)/etc/dinit.d/recovery \
		$(TARGET_DIR)/etc/dinit.d/serial-debug-shell
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/etc/fstab \
		$(TARGET_DIR)/etc/fstab
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/etc/iwd/main.conf \
		$(TARGET_DIR)/etc/iwd/main.conf
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/etc/resolv.conf \
		$(TARGET_DIR)/etc/resolv.conf
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/etc/machine-id \
		$(TARGET_DIR)/etc/machine-id
	$(INSTALL) -m 0600 $(ROKI_DINIT_RC_PKGDIR)/files/etc/ssh/sshd_config \
		$(TARGET_DIR)/etc/ssh/sshd_config
	$(INSTALL) -m 0600 $(ROKI_DINIT_RC_PKGDIR)/files/etc/ssh/ssh_host_ed25519_key \
		$(TARGET_DIR)/etc/ssh/ssh_host_ed25519_key
	$(INSTALL) -m 0600 $(ROKI_DINIT_RC_PKGDIR)/files/etc/ssh/ssh_host_rsa_key \
		$(TARGET_DIR)/etc/ssh/ssh_host_rsa_key
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/etc/profile.d/locale.sh \
		$(TARGET_DIR)/etc/profile.d/locale.sh
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/usr/share/terminfo/f/foot-extra \
		$(TARGET_DIR)/usr/share/terminfo/f/foot-extra
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_PKGDIR)/files/usr/share/terminfo/f/foot-extra-direct \
		$(TARGET_DIR)/usr/share/terminfo/f/foot-extra-direct
	$(INSTALL) -m 0644 $(ROKI_DINIT_RC_SERVICE_FILES) \
		$(TARGET_DIR)/etc/dinit.d/
	$(INSTALL) -m 0755 $(ROKI_DINIT_RC_PKGDIR)/files/usr/lib/dinit/* \
		$(TARGET_DIR)/usr/lib/dinit/
	$(INSTALL) -m 0755 $(ROKI_DINIT_RC_PKGDIR)/files/usr/bin/which \
		$(TARGET_DIR)/usr/bin/which
	$(INSTALL) -m 0755 $(ROKI_DINIT_RC_PKGDIR)/files/usr/bin/clear \
		$(TARGET_DIR)/usr/bin/clear
	$(INSTALL) -m 0755 $(ROKI_DINIT_RC_PKGDIR)/files/usr/bin/reset \
		$(TARGET_DIR)/usr/bin/reset
endef

$(eval $(generic-package))
