# Wayland ecosystem: compositors, bars, launchers, lockers, capture tools.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- wayland ecosystem
    niri
    labwc
    river
    xwayland-satellite
    waybar
    ironbar
    nwg-panel
    nwg-look
    sfwbar
    tint2
    plank
    rofi
    wofi
    fuzzel
    mako
    fnott
    eww
    wbg
    swaybg
    swayidle
    swaylock-effects
    wlogout
    wlopm
    wlr-randr
    wpaperd
    hypridle
    hyprlock
    gtklock
    waylock
    gammastep
    wlsunset
    kanshi
    wev
    wtype
    ydotool
    grim
    slurp
    wl-clipboard
    wf-recorder
    xsettingsd
    xdotool
    xsel
    libsfdo
    picom
  
]
