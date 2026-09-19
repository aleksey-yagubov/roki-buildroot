ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILDROOT_DIR ?= $(ROOT)/.buildroot/current
OUTPUT_DIR ?= $(ROOT)/output
BR2_ARGS = O=$(OUTPUT_DIR) BR2_EXTERNAL=$(ROOT)

.PHONY: setup host-tools toolchain-wrapper defconfig xconfig menuconfig nconfig linux-xconfig linux-menuconfig save-defconfig build clean distclean show-buildroot package

setup:
	$(ROOT)/scripts/fetch-buildroot.sh

toolchain-wrapper:
	$(ROOT)/scripts/prepare-arch-toolchain.sh

host-tools:
	bash $(ROOT)/scripts/prepare-host-tools.sh "$(BUILDROOT_DIR)" "$(OUTPUT_DIR)"

defconfig:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) host-tools
	$(MAKE) toolchain-wrapper
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) roki_cm4_defconfig

xconfig:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) xconfig

menuconfig:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) menuconfig

nconfig:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) nconfig

linux-xconfig:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) linux-xconfig

linux-menuconfig:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) linux-menuconfig

save-defconfig:
	@test -f "$(OUTPUT_DIR)/.config" || { echo "Run 'make defconfig' first."; exit 1; }
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) \
		BR2_DEFCONFIG=$(ROOT)/configs/roki_cm4_defconfig savedefconfig

build:
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) host-tools
	$(MAKE) toolchain-wrapper
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) roki-cm4-wifi-firmware
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS)

package:
	@test -n "$(TARGET)" || { echo "Use: make package TARGET=<package-target>"; exit 1; }
	@test -d "$(BUILDROOT_DIR)" || { echo "Run 'make setup' first."; exit 1; }
	$(MAKE) host-tools
	$(MAKE) toolchain-wrapper
	@targets='$(TARGET)'; \
	unset TARGET MAKEFLAGS MAKEOVERRIDES; \
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) V=1 $$targets

clean:
	@test -d "$(BUILDROOT_DIR)" || exit 0
	$(MAKE) -C $(BUILDROOT_DIR) $(BR2_ARGS) clean

distclean:
	rm -rf $(OUTPUT_DIR)

show-buildroot:
	@readlink -f "$(BUILDROOT_DIR)"
