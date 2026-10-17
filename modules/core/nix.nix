# Nix daemon, garbage collection, unfree policy, nix-ld.
{ config, lib, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
    max-jobs = "auto";
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # steam, discord, nvidia drivers, obs, brave, ungoogled-chromium, corefonts
  # are all unfree; NixOS refuses them without this switch.
  nixpkgs.config.allowUnfree = true;

  # nix-ld runs prebuilt binaries (AppImages, downloaded Electron apps) against
  # the system loader without patchelf.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    zstd
    openssl
    curl
    icu
    libxml2
    libxcrypt
  ];
}
