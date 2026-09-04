#!/bin/bash
#
# oem trimming for the MotionSense board only.
#
# Same content as BoardConfig_IPC/luckfox-buildroot-oem-pre.sh plus the product
# trimming at the end of remove_data(). Kept as a separate file because the
# vendor script is shared by every other board config, so additions there would
# silently change images we do not build.

function lf_rm() {
    for file in "$@"; do
        if [ -e "$file" ]; then
            echo "Deleting: $file"
            rm -rf "$file"  
        #else
            #echo "File not found: $file" 
        fi
    done
}

# remove unused files
function remove_data()
{
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/*.aiisp
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/*.data
    
    # drm ( sample program required )
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libdrm*
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libdrm_rockchip*

    # kms
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libkms*

    # freetype
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libfreetype*

    # iconv
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libiconv*

    # rkAVS
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/librkAVS*
    
    # jpeg
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libjpeg*

    # png
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/lib/libpng*

    # vqefiles
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/share/vqefiles/*

    # mpp prebuilt test binaries (no cmake/makefile switch available)
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/mpi_enc_test
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/mpp_info_test
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/vpu_api_test

    # ISP IQ conversion tool (tuning-time only, not needed in product)
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/j2s4b_dev

    # ISP demo (build-time switch set to n, belt-and-suspenders)
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/rkisp_demo

    # RGA demo (build-time switch set to OFF, belt-and-suspenders)
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/rgaImDemo

    # ISP tuning tool server (development only, not needed in product)
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/rkaiq_tool_server

    # The stock IPC application. MotionSense replaces it, and leaving it in the
    # image is not merely wasteful:
    #
    #   [network.ntp]
    #   enable = 1
    #   refresh_time_s = 60
    #   ntp_server = 119.28.183.184
    #
    # rkipc carries its own NTP client, enabled by default, pointed at a server
    # this product has no reason to talk to. It applies the timezone offset to
    # the UTC it gets back and then shells out to busybox to write the result as
    # if it were UTC, so the clock lands a full offset ahead -- eight hours here
    # -- and stays there, because nothing else on this image corrects it.
    #
    # S99motionsense already calls RkLunch-stop.sh, but that cannot win: RkLunch
    # starts rkipc from post_chk, which it backgrounds, and post_chk first waits
    # for /userdata and loads modules. rkipc therefore appears a minute or two
    # into the boot, long after the stop call has run against a process that did
    # not exist yet.
    #
    # Removing the inis as well as the binary makes post_chk exit at its own
    # "not found rkipc.ini" check, which is after insmod_ko.sh (still needed)
    # and before the audio test and the camera. iqfiles stays: /etc/iqfiles is a
    # symlink to it and the daemon reads it through CFG_ISP_IQ_DIR.
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/bin/rkipc
    lf_rm $RK_PROJECT_PACKAGE_OEM_DIR/usr/share/rkipc-*.ini
}

#=========================
# run
#=========================
remove_data