# Aggregator for every package group.
#
# Order here is the order environment.systemPackages ends up in, and it is
# deliberate: it reproduces the original single-file list exactly, so the
# evaluated system-path derivation is identical to the pre-split one. Each
# group file is a plain function of `pkgs` (see the comment at the top of any
# of them) rather than a module contributing its own systemPackages, because
# the module system merges `imports` in REVERSE order - a module-per-group
# design silently produces a reversed package list.
{ config, lib, pkgs, ... }:

let
  shells = import ./shells.nix { inherit pkgs; };
  editorsGraphics = import ./editors-graphics.nix { inherit pkgs; };
  desktopApplications = import ./desktop-applications.nix { inherit pkgs; };
  wayland = import ./wayland.nix { inherit pkgs; };
  theming = import ./theming.nix { inherit pkgs; };
  filesystem = import ./filesystem.nix { inherit pkgs; };
  network = import ./network.nix { inherit pkgs; };
  virtualisation = import ./virtualisation.nix { inherit pkgs; };
  gaming = import ./gaming.nix { inherit pkgs; };
  development = import ./development.nix { inherit pkgs; };
  media = import ./media.nix { inherit pkgs; };
  gpuHardware = import ./gpu-hardware.nix { inherit pkgs; };
  audioMisc = import ./audio-misc.nix { inherit pkgs; };
  plasma = import ./plasma.nix { inherit pkgs; };
  xorgUtilities = import ./xorg-utilities.nix { inherit pkgs; };
in
{
  environment.systemPackages =
    shells
    ++ editorsGraphics
    ++ desktopApplications
    ++ wayland
    ++ theming
    ++ filesystem
    ++ network
    ++ virtualisation
    ++ gaming
    ++ development
    ++ media
    ++ gpuHardware
    ++ audioMisc
    ++ plasma
    ++ xorgUtilities;
}
