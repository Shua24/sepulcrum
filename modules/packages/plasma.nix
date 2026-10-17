# KDE/Plasma packages. These live under the `kdePackages` scope in nixpkgs, not at the top level. The `haruna` media player is top-level and lives in desktop-applications.nix.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs.kdePackages; [

    # Every KDE/Plasma package lives under the `kdePackages` scope in nixpkgs,
    # not at the top level.
    plasma-desktop
    plasma-workspace
    plasma-browser-integration
    plasma-firewall
    plasma-nm
    plasma-pa
    plasma-systemmonitor
    plasma-thunderbolt
    plasma-login-manager
    kwin
    kwin-x11
    kscreen
    kscreenlocker
    kinfocenter
    systemsettings
    powerdevil
    polkit-kde-agent-1
    kglobalacceld
    kmenuedit
    kactivitymanagerd
    kde-gtk-config
    kdeplasma-addons
    bluedevil
    breeze-gtk
    ksshaskpass
    kwallet
    kwallet-pam
    kwalletmanager
    kio
    kio-admin
    kio-extras
    kgamma
    kdialog
    kdeconnect-kde
    kdegraphics-thumbnailers
    ffmpegthumbs
    filelight
    gwenview
    kate
    kcalc
    konsole
    dolphin
    ark
    partitionmanager
    kdf
    kfind
    kompare
    spectacle
    phonon
    phonon-vlc
  
]
