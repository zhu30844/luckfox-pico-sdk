Kernel Media Process Platform (MPP) module

Source
------
https://github.com/ticklab/rockchip-kmpp at 723b37e6 (2023-06-13), without
its tools/ directory. Rockchip's kmpp for the RV1106: the rkvenc_540c driver,
the vepu540c H.264/H.265/JPEG HALs and rate control, built as mpp_vcodec.ko.
The files carry SPDX (GPL-2.0+ OR MIT) headers; the upstream repository has
no LICENSE file and is not an official Rockchip release. A Rockchip
maintainer calls it "an old version kmpp code for rv1106" in
https://github.com/rockchip-linux/mpp/issues/934.

The stock module in ../release_kmpp_rv1106_arm is newer (424abb9b,
2024-04-29) and is still what the SDK builds and ships. This directory is not
named "kmpp" on purpose: the SDK Makefiles build ../kmpp from source in place
of the prebuilt module as soon as it exists.

Local changes
-------------
vcodec/inc/rk_export_func.h: two callback slots added so the tables match
the ones rockit.ko 28ee389d (2024-04-20) registers: buf_queue_size after
buf_queue_pop in vcodec_mpibuf_fn, and notify at the end of vcodec_mpidev_fn.
Layout read from rockit.ko's relocations; the prototypes are not known and
nothing here calls them.

Build
-----
In the devcontainer, from this directory, against the SDK kernel build tree:

  W=/workspaces/luckfox-pico-sdk
  export PATH=$W/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/bin:$PATH
  make -C $W/sysdrv/source/kernel O=$W/sysdrv/source/objs_kernel ARCH=arm \
      CROSS_COMPILE=arm-rockchip830-linux-uclibcgnueabihf- M=$PWD modules

Status (2026-11-21, MotionSense Pro Max, kernel 5.10.160, stock rockit.ko)
---------------------------------------------------------------------------
Loads and probes. H.264 1080p30 encodes and decodes cleanly. MJPEG is
broken: the channel encodes, but the packets reaching userspace are wrong
(motionsense-agent logs "frame size error"). Not investigated yet.

rockit.ko does not unload (rmmod hangs in kthread_stop), so the module can
only be swapped at boot, in /oem/usr/ko/insmod_ko.sh.
