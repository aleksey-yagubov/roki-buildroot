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

## opencv4-contrib: module dependencies are missing from Kconfig

### Reproducer

Enable `BR2_PACKAGE_OPENCV4_CONTRIB_LIB_ARUCO` or
`BR2_PACKAGE_OPENCV4_CONTRIB_LIB_XIMGPROC` without manually selecting their
base OpenCV modules.

### Actual result

The generated OpenCV CMake configuration requests the contrib module, but
OpenCV 4.13 disables it as unavailable:

- `aruco` requires `opencv_objdetect`;
- `ximgproc` requires `opencv_video`.

Buildroot's contrib Kconfig symbols currently select neither dependency.
The image consequently contains neither `cv2.aruco` nor `cv2.ximgproc`, even
though both contrib symbols are enabled.

### Expected result

Selecting a contrib module should select all of its mandatory OpenCV module
dependencies, so the requested module and its Python binding are built.

### Proposed upstream fix

Add `select BR2_PACKAGE_OPENCV4_LIB_OBJDETECT` to the `aruco` symbol and
`select BR2_PACKAGE_OPENCV4_LIB_VIDEO` to the `ximgproc` symbol.

### Local workaround

`patches/buildroot/0022-opencv4-contrib-select-required-modules.patch`
adds those selections. The Roki defconfig also lists the two base modules
explicitly for readability.

## opencv4: objdetect unnecessarily requires DNN and Protobuf

### Actual result

Buildroot makes `BR2_PACKAGE_OPENCV4_LIB_OBJDETECT` select `dnn` and `ml`,
which in turn pulls Protobuf. In OpenCV 4.13, `objdetect` has only `core`,
`imgproc`, and `calib3d` as mandatory dependencies; `dnn` is optional.

### Impact

ArUco requires `objdetect`, so enabling ArUco brings the whole unused DNN and
Protobuf stack into the ROKI image.

### Local workaround

`patches/buildroot/0024-opencv4-objdetect-make-dnn-optional.patch` preserves
the mandatory dependencies and removes the incorrect DNN and Protobuf
requirements. The image explicitly disables unused OpenCV signal, Orbbec and
Intel ITT tracing through patches `0023`, `0025`, and `0026`.
