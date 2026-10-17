# Users and sudo policy.
{ config, lib, pkgs, ... }:

{
  users.users.aulus = {
    isNormalUser = true;
    description = "Carolus";
    # User-wide only. bash stays users.defaultUserShell for root and anything
    # that shells out, because most of the system assumes bash. See NOTES.md.
    shell = pkgs.yash;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "render"
      "audio"
      "input"
      "storage"
      "lp"
    ];
  };
  security.sudo.wheelNeedsPassword = true;

  environment.shells = [ pkgs.yash ];
}
