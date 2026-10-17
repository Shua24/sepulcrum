# Wine, Proton tooling and gaming overlays.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- gaming
    wine
    winetricks
    protonup-qt
    heroic
    gamescope
    gamemode
    mangohud
    goverlay
    vkbasalt
    bottles
    steam-run
  
]
