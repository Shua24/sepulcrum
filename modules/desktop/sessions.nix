# Display manager, desktop sessions and XDG portals.
{ config, lib, pkgs, ... }:

{
  # All of the sessions you had, per your call. GDM is the single display
  # manager: you had both gdm.service and plasmalogin.service enabled on Arch,
  # which cannot work here since exactly one DM may own the login screen.
  services.displayManager.gdm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.windowManager.icewm.enable = true;
  programs.niri.enable = true;
  programs.labwc.enable = true;
  programs.river-classic.enable = true;

  # Plasma is the primary session. The plasma6 and niri modules both define
  # services.displayManager.defaultSession at equal priority, so enabling both
  # is a hard conflict unless one is forced. Verified by evaluating the module
  # system: "has conflicting definition values: plasma vs niri".
  services.displayManager.defaultSession = lib.mkForce "plasma";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };
}
