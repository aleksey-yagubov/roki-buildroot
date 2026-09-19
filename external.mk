include $(sort $(wildcard $(BR2_EXTERNAL_ROKI_PATH)/package/*/*.mk))

# The CM4 head always runs on BCM2711's Cortex-A72 cores. Keep Kbuild's
# upstream -O2 policy, but use its exact Armv8-A ISA baseline and tune for A72.
LINUX_CFLAGS += -march=armv8-a+crc -mtune=cortex-a72
