#!/bin/bash
#################################################
# 	MotionSense board config: Luckfox Pico Pro Max
#
# Derived from BoardConfig-SPI_NAND-Buildroot-RV1106_Luckfox_Pico_Pro_Max-IPC.mk.
# Lives in its own BoardConfig_* directory so that syncing upstream never
# conflicts: everything here is an addition, nothing vendor-owned is edited.
#
# Not listed in build.sh's numbered lunch menu (that array is hardcoded);
# pick it through the last menu entry, "custom".
#################################################
export LF_ORIGIN_BOARD_CONFIG=BoardConfig-SPI_NAND-Buildroot-RV1106_MotionSense_Pro_Max-IPC.mk

# Target CHIP
export RK_CHIP=rv1106

# Target APP. Each app builds only for a name it knows, so this leaves rkipc out.
export RK_APP_TYPE=MOTIONSENSE

# CMA size
export RK_BOOTARGS_CMA_SIZE="66M"

# Kernel dts. Our own, so the vendor Pro Max dts stays untouched.
export RK_KERNEL_DTS=rv1106g-motionsense-pro-max.dts

#################################################
#	BOOT_MEDIUM
#################################################
export RK_BOOT_MEDIUM=spi_nand
export RK_UBOOT_DEFCONFIG_FRAGMENT="rk-sfc.config rk-vendor-storage.config"
export RK_KERNEL_DEFCONFIG_FRAGMENT=rv1106-vendor-storage.config

#################################################
#	PARTITION
#################################################
# Total 255MB of the 256MB SPI NAND. userdata takes the rest and holds the
# update package. See Partitions in the app's docs/BUILD.md.
# boot, rootfs and oem sit between recovery and userdata, which must not move,
# so an update could later resize those three against each other.
# Nothing validates images against these sizes, so check after building.
# vnvm is Rockchip's vendor storage: the name is the one U-Boot and the kernel look for.
export RK_PARTITION_CMD_IN_ENV="256K(env),256K@256K(idblock),512K(uboot),512K(misc),8M(recovery),6M(boot),48M(rootfs),65024K(oem),512K(vnvm),130560K(userdata)"
export RK_PARTITION_FS_TYPE_CFG=rootfs@IGNORE@ubifs,oem@/oem@ubifs,userdata@/userdata@ubifs

#################################################
#	ROOTFS
#################################################
export LF_TARGET_ROOTFS=buildroot
export RK_BUILDROOT_DEFCONFIG=motionsense_defconfig

export RK_ARCH=arm
export RK_TOOLCHAIN_CROSS=arm-rockchip830-linux-uclibcgnueabihf
# A blank misc boots normally. The vendor default, recovery-misc.img, boots
# into recovery with --wipe_all; wipe_all-misc.img does not exist in the SDK.
export RK_MISC=blank-misc.img
export RK_UBOOT_DEFCONFIG=luckfox_rv1106_uboot_defconfig
export RK_KERNEL_DEFCONFIG=luckfox_rv1106_linux_defconfig

#################################################
#	CAMERA
#################################################
export RK_CAMERA_SENSOR_IQFILES="sc4336_OT01_40IRC_F16.json sc3336_CMK-OT2119-PC1_30IRC-F16.json mis5001_CMK-OT2115-PC1_30IRC-F16.json"
export RK_CAMERA_SENSOR_CAC_BIN="CAC_sc4336_OT01_40IRC_F16"

#################################################
#	FEATURES
#################################################
# Keep the app on its own partition so it can be reflashed without rootfs.
export RK_BUILD_APP_TO_OEM_PARTITION=y

# recovery.img: a kernel and a busybox ramdisk that flash an update package
export RK_ENABLE_RECOVERY=y
export RK_RECOVERY_KERNEL_DEFCONFIG_FRAGMENT="rv1106-recovery.config"
# A symlink to the app's update/recovery.sh; it flashes a package in /userdata
export RK_RECOVERY_LUNCH_SCRIPT=motionsense-recovery.sh

# Everything below is off: this is a product image, not an evaluation one.
export RK_ENABLE_ROCKCHIP_TEST=n

# No onboard wifi on the Pro Max, and no SDIO module in this design.
export RK_ENABLE_WIFI=n

# rockchip sample programs (media/samples)
export RK_ENABLE_SAMPLE=n

# luckfox hardware test examples (media/luckfox/examples)
export RK_ENABLE_LUCKFOX_TEST=n

# sysutils test examples (media/sysutils/examples)
# NOTE: sysutils lib+headers always build (needed by rkipc); this only gates examples
export RK_ENABLE_SYSUTILS_TESTS=n

#################################################
# 	PRE and POST
#################################################
# Our own oem trimming, so the vendor script stays shared-and-unmodified.
export RK_PRE_BUILD_OEM_SCRIPT=motionsense-oem-pre.sh
export RK_PRE_BUILD_USERDATA_SCRIPT=luckfox-userdata-pre.sh

# overlay-luckfox-* are symlinks into BoardConfig_IPC/overlay; post_overlay
# resolves these against this directory and skips missing ones silently.
export RK_POST_OVERLAY="overlay-luckfox-config overlay-luckfox-buildroot-init overlay-luckfox-buildroot-shadow overlay-motionsense"
