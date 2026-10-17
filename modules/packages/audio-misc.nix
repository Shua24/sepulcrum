# Audio, accessibility, input remapping and low-level debugging tools.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- audio, accessibility, misc
    piper-tts
    orca
    speechd
    seahorse
    android-tools
    wireplumber
    pavucontrol
    alsa-utils
    playerctl
    pamixer
    brightnessctl
    keyd
    patchelf
    binutils
    gdb
    strace
    valgrind
  
]
