#!/bin/bash
# rootfs trimming for the MotionSense board: what a buildroot option cannot leave out.
set -e
R=$RK_PROJECT_PACKAGE_ROOTFS_DIR
[ -d "$R/etc" ] || { echo "motionsense-rootfs-post: no rootfs staging at '$R'" >&2; exit 1; }

# libv4l's utilities come as one set; media-ctl and v4l2-ctl stay.
rm -fv "$R"/usr/bin/{v4l2-compliance,cec-ctl,cec-compliance}

# Installed along with ssh-keygen, which sshd's start script needs.
rm -fv "$R"/usr/bin/ssh-keyscan

# usb0 has a fixed address (S51usbaddr); dhcpcd would add a link-local one.
grep -qx 'denyinterfaces usb0' "$R/etc/dhcpcd.conf" || echo 'denyinterfaces usb0' >> "$R/etc/dhcpcd.conf"
