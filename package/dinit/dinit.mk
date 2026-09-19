################################################################################
#
# dinit
#
################################################################################

DINIT_VERSION = 0.22.1
DINIT_SITE = $(call github,davmac314,dinit,v$(DINIT_VERSION))
DINIT_LICENSE = Apache-2.0
DINIT_LICENSE_FILES = LICENSE

define DINIT_CONFIGURE_CMDS
	cp $(DINIT_PKGDIR)/mconfig $(@D)/mconfig
	$(SED) \
		's|@TARGET_CXX@|$(TARGET_CXX)|' \
		-e 's|@TARGET_LDFLAGS@|$(TARGET_LDFLAGS)|' \
		$(@D)/mconfig
endef

define DINIT_BUILD_CMDS
	$(MAKE) -C $(@D)/build CXX="$(HOSTCXX)"
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/src
endef

define DINIT_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/src \
		DESTDIR=$(TARGET_DIR) STRIPOPTS= install
endef

$(eval $(generic-package))
