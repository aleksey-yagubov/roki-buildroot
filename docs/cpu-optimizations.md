# BCM2711 userspace CPU baseline

The CM4 uses four Cortex-A72 cores in the BCM2711. Target userspace is built
for exactly this instruction baseline:

```
-O3 -march=armv8-a+crc -mtune=cortex-a72
```

`armv8-a` includes the mandatory AArch64 Advanced SIMD (NEON) and scalar
floating-point instructions. BCM2711 implements the Armv8 CRC extension, but
not the optional AES, PMULL, SHA1, or SHA2 crypto extensions. Do not add
Armv8.1+ or later extensions: Cortex-A72 does not implement LSE atomics, FP16
arithmetic, dot-product, FHM, BF16, I8MM, SVE, SVE2, or SME.

Package-specific configuration:

- OpenCV uses `CPU_BASELINE=NEON` and no CPU dispatch variants.
- NumPy uses `cpu-baseline=NEON` and no CPU dispatch variants.
- libcamera and its Python binding inherit the common target flags; its
  performance-critical pipeline and IPA remain native C++ code.

OpenBLAS is deliberately not enabled. It accelerates NumPy BLAS/LAPACK calls,
not the OpenCV image operations used by the head, and can introduce extra
threads and image size. Re-evaluate it only after profiling a workload that
uses NumPy matrix multiplication or linear algebra.
