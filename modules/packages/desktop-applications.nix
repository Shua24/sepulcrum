# Browsers, comms, office, and the GNOME/XFCE application sets.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- desktop applications
    firefox
    brave
    ungoogled-chromium
    floorp-bin
    tor-browser
    epiphany
    netsurf-browser
    thunderbird
    element-desktop
    discord
    telegram-desktop
    keepassxc
    libreoffice-stable
    vlc
    mpv
    qbittorrent
    haruna
    simple-scan
    loupe
    papers
    showtime
    decibels
    yelp
    gnome-tour
    gnome-user-share
    gnome-disk-utility
    gnome-system-monitor
    gnome-text-editor
    gnome-tweaks
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-contacts
    gnome-logs
    gnome-maps
    gnome-music
    gnome-weather
    gnome-characters
    gnome-color-manager
    gnome-font-viewer
    gnome-backgrounds
    gnome-connections
    gnome-remote-desktop
    grilo-plugins
    rygel
    gvfs
    sushi
    baobab
    malcontent
    gnome-boxes
    nautilus
    thunar
    thunar-volman
    xfce4-appfinder
    xfce4-panel
    xfce4-power-manager
    xfce4-session
    xfce4-settings
    xfce4-terminal
    xfdesktop
    xfwm4
    xfce4-screensaver
  
]
