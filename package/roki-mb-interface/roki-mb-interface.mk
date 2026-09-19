################################################################################
#
# roki-mb-interface
#
################################################################################

ROKI_MB_INTERFACE_VERSION = e4087466c7ddca0fd1d9d342eb4e09200f435b02
ROKI_MB_INTERFACE_SITE = $(call github,tndrd,roki-mb-interface,$(ROKI_MB_INTERFACE_VERSION))
ROKI_MB_INTERFACE_LICENSE = unknown
ROKI_MB_INTERFACE_DEPENDENCIES = python3 python-pybind

# Gitlinks recorded by ROKI_MB_INTERFACE_VERSION. Only these submodules are
# needed at build time; pybind11 comes from Buildroot and GoogleTest is unused.
ROKI_MB_INTERFACE_RCB4_VERSION = af9ade42eddcfa0c3ba0ca28a426d6df50ea0d24
ROKI_MB_INTERFACE_MB_SERVICE_VERSION = 0d64f8bb28cfe816595d07cbd3bd15218c5c0982
ROKI_MB_INTERFACE_RCB4_ARCHIVE = \
	$(call github,tndrd,rcb4-base-class,$(ROKI_MB_INTERFACE_RCB4_VERSION))/$(ROKI_MB_INTERFACE_RCB4_VERSION).tar.gz
ROKI_MB_INTERFACE_MB_SERVICE_ARCHIVE = \
	$(call github,tndrd,roki-mb-service,$(ROKI_MB_INTERFACE_MB_SERVICE_VERSION))/$(ROKI_MB_INTERFACE_MB_SERVICE_VERSION).tar.gz
ROKI_MB_INTERFACE_EXTRA_DOWNLOADS = \
	$(ROKI_MB_INTERFACE_RCB4_ARCHIVE) \
	$(ROKI_MB_INTERFACE_MB_SERVICE_ARCHIVE)

define ROKI_MB_INTERFACE_EXTRACT_SUBMODULES
	mkdir -p $(@D)/deps/rcb4-base-class $(@D)/deps/roki-mb-service
	$(call suitable-extractor,$(notdir $(ROKI_MB_INTERFACE_RCB4_ARCHIVE))) \
		$(ROKI_MB_INTERFACE_DL_DIR)/$(notdir $(ROKI_MB_INTERFACE_RCB4_ARCHIVE)) | \
		$(TAR) --strip-components=1 -C $(@D)/deps/rcb4-base-class $(TAR_OPTIONS) -
	$(call suitable-extractor,$(notdir $(ROKI_MB_INTERFACE_MB_SERVICE_ARCHIVE))) \
		$(ROKI_MB_INTERFACE_DL_DIR)/$(notdir $(ROKI_MB_INTERFACE_MB_SERVICE_ARCHIVE)) | \
		$(TAR) --strip-components=1 -C $(@D)/deps/roki-mb-service $(TAR_OPTIONS) -
endef
ROKI_MB_INTERFACE_POST_EXTRACT_HOOKS += ROKI_MB_INTERFACE_EXTRACT_SUBMODULES

ROKI_MB_INTERFACE_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=MinSizeRel \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
	-DPYBIND11_FINDPYTHON=ON \
	-DPython3_EXECUTABLE=$(HOST_DIR)/bin/python3 \
	-DPython3_INCLUDE_DIR=$(STAGING_DIR)/usr/include/python$(PYTHON3_VERSION_MAJOR) \
	-DPython3_LIBRARY=$(STAGING_DIR)/usr/lib/libpython$(PYTHON3_VERSION_MAJOR).so

define ROKI_MB_INTERFACE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/Roki*.so \
		$(TARGET_DIR)/usr/lib/python$(PYTHON3_VERSION_MAJOR)/site-packages/Roki.so
endef

$(eval $(cmake-package))
