# X11 server utilities. Plain top-level names in nixpkgs; the `xorg.*` scope no longer exists as such.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # X11 server utilities. These are plain top-level names in nixpkgs; the
    # `xorg.*` scope no longer exists as such.
    xorg-server
    xterm
    twm
    xclock
    xev
    xinput
    xhost
    xrefresh
    xkill
    xwd
    xwud
    xlsclients
    xlsatoms
    xset
    xsetroot
    xpr
    xgamma
    x11perf
    xcursorgen
    xdriinfo
    xvinfo
    xbacklight
    xkbevd
    xkbutils
    xcmsdb
    smproxy
    sessreg
    bdftopcf
    font-util
  
]
