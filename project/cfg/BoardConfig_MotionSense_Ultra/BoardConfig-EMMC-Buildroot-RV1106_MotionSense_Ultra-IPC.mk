#!/bin/bash
#################################################
# 	MotionSense board config: Luckfox Pico Ultra
#
# PLACEHOLDER. Hardware settings are copied unchanged from the vendor
# BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Ultra-IPC.mk (boot medium,
# dts, partitions, u-boot fragments); the software side is MotionSense's
# (buildroot defconfig, oem trimming, overlays), shared with Pro Max through
# symlinks. It exists so CI builds both boards; it is not a working product
# image yet:
#
#  - S99motionsense keeps everything on /mnt/sdcard and gives up after 30 s
#    without it, and the vendor Ultra dts gives the SD controller to the
#    onboard wifi. MotionSense is in oem but will not start.
#  - Uses the vendor dts as is; no rv1106g-motionsense-ultra.dts yet.
#
# Lives in its own directory because CI builds one board per directory.
# Not in build.sh's numbered lunch menu; pick it through "custom".
#################################################
export LF_ORIGIN_BOARD_CONFIG=BoardConfig-EMMC-Buildroot-RV1106_MotionSense_Ultra-IPC.mk

# Target CHIP
export RK_CHIP=rv1106

# Target APP
export RK_APP_TYPE=RKIPC_RV1106

# CMA size
export RK_BOOTARGS_CMA_SIZE="66M"

# Kernel dts (vendor, for now)
export RK_KERNEL_DTS=rv1106g-luckfox-pico-ultra.dts

#################################################
#	BOOT_MEDIUM
#################################################
export RK_BOOT_MEDIUM=emmc
export RK_UBOOT_DEFCONFIG_FRAGMENT="rk-emmc.config rv1106-luckfox-rgb-reset.config"

#################################################
#	PARTITION
#################################################
# Vendor Ultra layout, 8GB eMMC.
export RK_PARTITION_CMD_IN_ENV="32K(env),512K@32K(idblock),256K(uboot),32M(boot),512M(oem),256M(userdata),6G(rootfs)"
export RK_PARTITION_FS_TYPE_CFG=rootfs@IGNORE@ext4,userdata@/userdata@ext4,oem@/oem@ext4

#################################################
#	ROOTFS
#################################################
export LF_TARGET_ROOTFS=buildroot
# MotionSense's, not the vendor luckfox_pico_w_defconfig: that one lacks the
# sqlite and libyaml MotionSense links against, and does not use the dl/ and
# ccache dirs CI caches.
export RK_BUILDROOT_DEFCONFIG=motionsense_defconfig

export RK_ARCH=arm
export RK_TOOLCHAIN_CROSS=arm-rockchip830-linux-uclibcgnueabihf
export RK_MISC=wipe_all-misc.img
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
export RK_BUILD_APP_TO_OEM_PARTITION=y

# Same as Pro Max: a product image, not an evaluation one.
export RK_ENABLE_ROCKCHIP_TEST=n
export RK_ENABLE_SAMPLE=n
export RK_ENABLE_LUCKFOX_TEST=n
export RK_ENABLE_SYSUTILS_TESTS=n

# Off until decided: the vendor turns on the AIC8800DC wifi (Ultra W only)
# and the rv1106-bt.config kernel fragment, but motionsense_defconfig has no
# wifi or bluetooth userspace.
export RK_ENABLE_WIFI=n

#################################################
# 	PRE and POST
#################################################
# Both scripts are symlinks: oem trimming from Pro Max, userdata from
# BoardConfig_IPC.
export RK_PRE_BUILD_OEM_SCRIPT=motionsense-oem-pre.sh
export RK_PRE_BUILD_USERDATA_SCRIPT=luckfox-userdata-pre.sh

# All symlinks: overlay-luckfox-* into BoardConfig_IPC/overlay,
# overlay-motionsense into BoardConfig_MotionSense_Pro_Max/overlay.
export RK_POST_OVERLAY="overlay-luckfox-config overlay-luckfox-buildroot-init overlay-luckfox-buildroot-shadow overlay-motionsense"
