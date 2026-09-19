################################################################################
#
# libcamera-rpi
#
################################################################################

LIBCAMERA_RPI_VERSION = 0.7.2+rpt20260817
LIBCAMERA_RPI_SITE = $(call github,raspberrypi,libcamera,v$(LIBCAMERA_RPI_VERSION))
LIBCAMERA_RPI_LICENSE = \
	BSD-2-Clause, GPL-2.0 with Linux-syscall-note or BSD-3-Clause, LGPL-2.1+
LIBCAMERA_RPI_LICENSE_FILES = \
	LICENSES/BSD-2-Clause.txt \
	LICENSES/GPL-2.0-only.txt \
	LICENSES/LGPL-2.1-or-later.txt
LIBCAMERA_RPI_DEPENDENCIES = \
	arducam-pivariety-sdk \
	gstreamer1 \
	gst1-plugins-base \
	libevent \
	libyaml \
	python3 \
	python-pybind
LIBCAMERA_RPI_INSTALL_STAGING = YES
LIBCAMERA_RPI_CXXFLAGS = $(TARGET_CXXFLAGS) -faligned-new
LIBCAMERA_RPI_DEFAULT_LIBRARY = $(if $(BR2_STATIC_LIBS),static,shared)
LIBCAMERA_RPI_CONF_OPTS = \
	-Dauto_features=disabled \
	-Dandroid=disabled \
	-Dcam=enabled \
	-Dcam-jpeg=disabled \
	-Dcam-output-kms=disabled \
	-Dcam-output-sdl2=disabled \
	-Ddocumentation=disabled \
	-Dgstreamer=enabled \
	-Dipas=rpi/vc4 \
	-Dlc-compliance=disabled \
	-Dlibdw=disabled \
	-Dlibunwind=disabled \
	-Dpipelines=rpi/vc4 \
	-Dpycamera=enabled \
	-Dqcam=disabled \
	-Drpi-awb-nn=disabled \
	-Dsoftisp-gpu=disabled \
	-Dtest=false \
	-Dtracing=disabled \
	-Dudev=disabled \
	-Dv4l2=disabled \
	-Dwerror=false

define LIBCAMERA_RPI_CONFIGURE_CMDS
	rm -rf $(@D)/buildroot-build
	mkdir -p $(@D)/buildroot-build
	sed \
		-e "s%@TARGET_CC@%$(TARGET_CC)%g" \
		-e "s%@TARGET_CXX@%$(TARGET_CXX)%g" \
		-e "s%@TARGET_AR@%$(TARGET_AR)%g" \
		-e "s%@TARGET_FC@%/bin/false%g" \
		-e "s%@TARGET_STRIP@%$(TARGET_STRIP)%g" \
		-e "s%@TARGET_ARCH@%aarch64%g" \
		-e "s%@TARGET_CPU@%$(GCC_TARGET_CPU)%g" \
		-e "s%@TARGET_ENDIAN@%little%g" \
		-e "s%@TARGET_FCFLAGS@%%g" \
		-e "s%@TARGET_CFLAGS@%$(call make-sq-comma-list,$(LIBCAMERA_RPI_CFLAGS))%g" \
		-e "s%@TARGET_LDFLAGS@%$(call make-sq-comma-list,$(LIBCAMERA_RPI_LDFLAGS))%g" \
		-e "s%@TARGET_CXXFLAGS@%$(call make-sq-comma-list,$(LIBCAMERA_RPI_CXXFLAGS))%g" \
		-e "s%@BR2_CMAKE@%$(BR2_CMAKE)%g" \
		-e "s%@PKGCONF_HOST_BINARY@%/usr/bin/pkgconf%g" \
		-e "s%@HOST_DIR@%$(HOST_DIR)%g" \
		-e "s%@STAGING_DIR@%$(STAGING_DIR)%g" \
		-e "s%@STATIC@%false%g" \
		$(TOPDIR)/support/misc/cross-compilation.conf.in \
		> $(@D)/buildroot-build/cross-compilation.conf
	PATH=$(BR_PATH) \
	CC_FOR_BUILD="$(HOSTCC)" \
	CXX_FOR_BUILD="$(HOSTCXX)" \
	PYTHONNOUSERSITE=y \
	/usr/bin/meson setup \
		--prefix=/usr \
		--libdir=lib \
		--default-library=$(LIBCAMERA_RPI_DEFAULT_LIBRARY) \
		--buildtype=$(if $(BR2_ENABLE_RUNTIME_DEBUG),debug,release) \
		--cross-file=$(@D)/buildroot-build/cross-compilation.conf \
		-Db_pie=false \
		-Db_staticpic=$(if $(BR2_m68k_cf),false,true) \
		-Dstrip=false \
		-Dbuild.pkg_config_path=/usr/lib/pkgconfig \
		$(LIBCAMERA_RPI_CONF_OPTS) \
		$(@D) $(@D)/buildroot-build
endef

define LIBCAMERA_RPI_BUILD_CMDS
	$(TARGET_MAKE_ENV) PYTHONNOUSERSITE=y /usr/bin/ninja $(NINJA_OPTS) -C $(@D)/buildroot-build
endef

define LIBCAMERA_RPI_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) PYTHONNOUSERSITE=y DESTDIR=$(STAGING_DIR) \
		/usr/bin/ninja $(NINJA_OPTS) -C $(@D)/buildroot-build install
endef

define LIBCAMERA_RPI_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) PYTHONNOUSERSITE=y DESTDIR=$(TARGET_DIR) \
		/usr/bin/ninja $(NINJA_OPTS) -C $(@D)/buildroot-build install
endef

$(eval $(generic-package))
