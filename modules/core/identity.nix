# Host identity: name, networking backend, timezone, locale, keyboard.
{ config, lib, pkgs, ... }:

{
  networking.hostName = "sepulcrum";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Jakarta";

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };
  # Matches /etc/vconsole.conf on the CachyOS install: KEYMAP=us, XKBLAYOUT=us.
  console.keyMap = "us";
  services.xserver.xkb = {
    layout = "us";
    model = "pc105";
  };
}
