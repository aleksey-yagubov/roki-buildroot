# Buildroot Upstream Issues

## alsa-utils: `alsactl` is built although it is disabled

### Reproducer

Enable `BR2_PACKAGE_ALSA_UTILS=y`, disable
`BR2_PACKAGE_ALSA_UTILS_ALSACTL`, and disable
`BR2_PACKAGE_ALSA_LIB_UCM`.

### Actual result

`package/alsa-utils/alsa-utils.mk` selects which binaries are installed in the
target rootfs, but invokes upstream `make all`. Upstream `Makefile.am` always
contains `alsactl` in `SUBDIRS`, and conditionally adds `alsaucm` only by
checking the UCM header. The header is installed even when UCM implementation
is disabled in alsa-lib. Both utilities are therefore built despite being
disabled in Buildroot and link against absent UCM symbols.

### Expected result

Disabled ALSA utilities should not be built, or `alsa-utils` should ensure
that UCM-related utilities are not compiled when UCM is unavailable.

### Proposed upstream fix

Make the alsa-utils package pass a configure option or build only the selected
subdirectories. Alternatively, make upstream conditionally include `alsactl`
only when its required ALSA features are available.

### Local workaround

`global-patches/alsa-utils/0001-do-not-build-unused-alsactl.patch` removes
`alsactl` and `alsaucm` from the upstream `SUBDIRS` list for this fixed image.
