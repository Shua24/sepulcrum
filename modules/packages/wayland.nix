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

    # --- wallpaper daemon (awww, formerly swww)
    #
    # There is NO `services.awww` NixOS option. Verified against the pinned
    # nixpkgs revision: `grep -rln awww $NIXPKGS/nixos/modules` returns nothing,
    # and importing a module that defines it fails evaluation outright with
    #   error: The option `services.awww' does not exist.
    # So the package only goes on PATH; the compositor owns the daemon.
    #
    # niri already does that: ~/.config/niri/config.kdl has
    #   spawn-at-startup "awww-daemon"
    # and ~/.config/niri/scripts/switcher.sh drives it with
    #   awww img <file> --transition-type random --transition-duration 5
    #
    # Do NOT add a systemd user unit for awww-daemon on top of that: a second
    # daemon cannot take the same socket, and with Restart=always it would loop.
    # If a session ever stops spawning it itself, add the unit elsewhere AND
    # delete the spawn-at-startup line, not both.
    awww
]
