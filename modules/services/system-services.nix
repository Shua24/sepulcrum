# Long-running system services: ssh, firmware, power, indexing, printing.
{ config, lib, pkgs, ... }:

{
  services.openssh.enable = true;
  services.fwupd.enable = true;
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.printing.enable = true;
  services.blueman.enable = true;
  services.logrotate.enable = true;
  services.fstrim.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # NOTE: services.udev.packages = [ android-udev-rules ] was dropped.
  # nixpkgs removed that package ("superseded by built-in systemd uaccess
  # rules"), and android-tools in systemPackages is enough for adb/fastboot.
}
