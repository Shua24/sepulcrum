# fcitx5 with mozc.
{ config, lib, pkgs, ... }:

{
  # fcitx5 + mozc, matching the CachyOS setup. Only real addons go in the
  # addons list: the module builds pkgs.fcitx5-with-addons with withConfigtool
  # defaulted to true, which already pulls in fcitx5-configtool and fcitx5-gtk
  # (verified in pkgs/tools/inputmethods/fcitx5/with-addons.nix). Adding them
  # again here is redundant.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
    ];
  };
}
