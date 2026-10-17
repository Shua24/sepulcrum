# Filesystems, partitioning, disks, sensors.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- filesystem, disk, system
    btrfs-progs
    snapper
    e2fsprogs
    xfsprogs
    dosfstools
    exfatprogs
    f2fs-tools
    jfsutils
    nilfs-utils
    lvm2
    mdadm
    dmraid
    cryptsetup
    smartmontools
    sg3_utils
    lsscsi
    usb-modeswitch
    sysfsutils
    mtools
    hdparm
    parted
    gparted
    gptfdisk
    nvme-cli
    hwinfo
    dmidecode
    pciutils
    usbutils
    lsb-release
    cpupower-gui
    powertop
    lm_sensors
    acpi
    evtest
    libinput
    libinput-gestures
    fsarchiver
    rclone
  
]
