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
}

#=========================
# run
#=========================
remove_data