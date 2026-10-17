# Host identity: name, networking backend, timezone, locale, keyboard.
{ config, lib, pkgs, ... }:

{
  networking.hostName = "sepulcrum";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Jakarta";
  # EDITOR is set here rather than via programs.*.defaultEditor, which uses
  # mkOverride 900 and would silently beat any later assignment. VISUAL is set
  # too: many tools read it first and only fall back to EDITOR.
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

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
