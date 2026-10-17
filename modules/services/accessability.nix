# Night light: colour-temperature shifting for both session types.
#
# Two tools, one job, so each is pinned to the session type it belongs to. They
# must never run in the same session: both rewrite the display's gamma ramp and
# the last writer wins, which shows up as flicker or a stuck temperature.
#
#   X11 sessions        -> redshift   (services.redshift)
#   Wayland sessions    -> gammastep  (hand-written user service; nixpkgs has
#                                      no services.gammastep module)
#
# Plasma and GNOME ship their own night light on both session types, so the
# Wayland guard skips them - otherwise gammastep would fight the desktop's
# built-in one. The desktops without one are niri, labwc and river.
{ config, lib, pkgs, ... }:

let
  dayTemperature = 6500;
  nightTemperature = 2700;
in
{
  # Geolocation. Both tools ask geoclue2 for the position instead of having
  # coordinates baked in, so this config works anywhere rather than in one city.
  #
  # services.redshift only reads location.latitude/longitude when the provider is
  # "manual" - with "geoclue2" it passes the provider name straight through and
  # never touches them. That is why no coordinates are declared here.
  location.provider = "geoclue2";

  services.geoclue2 = {
    enable = true;
    # Both tools are system components requesting a position. Without an explicit
    # grant geoclue2 refuses the request, so these entries are load-bearing.
    appConfig.redshift = {
      isAllowed = true;
      isSystem = true;
    };
    appConfig.gammastep = {
      isAllowed = true;
      isSystem = true;
    };
  };

  # ------------------------------------------------------------------ X11
  services.redshift = {
    enable = true;
    temperature = {
      day = dayTemperature;
      night = nightTemperature;
    };
    brightness = {
      day = "1.0";
      night = "0.8";
    };
  };

  # The redshift module creates systemd.user.services.redshift itself, so the
  # session guard is attached to that unit rather than through a
  # services.redshift.systemd option (which does not exist). unitConfig is a
  # plain attrsOf, so setting it here merges with the module's own definition.
  # Without the condition the service would also start under Wayland, where
  # gammastep is the one doing the work.
  systemd.user.services.redshift.unitConfig.ConditionEnvironment =
    [ "XDG_SESSION_TYPE=x11" ];

  # Geolocation grants are declared above, next to location.provider.

  # -------------------------------------------------------------- Wayland
  #
  # No services.gammastep option exists in nixpkgs, so the unit is declared here.
  # Flags mirror redshift's so both tools produce the same curve.
  systemd.user.services.gammastep = {
    description = "Gammastep colour temperature adjuster (Wayland)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig = {
      ConditionEnvironment = [ "XDG_SESSION_TYPE=wayland" ];
    };
    serviceConfig = {
      # Skips the desktops that already provide night light. Conditions are
      # ANDed, so this needs a single test rather than several
      # ConditionEnvironment lines. Exits 1 (skip) for KDE and GNOME.
      ExecCondition = toString (pkgs.writeShellScript "gammastep-session-guard" ''
        case "''${XDG_CURRENT_DESKTOP:-}" in
          *KDE*|*GNOME*) exit 1 ;;
        esac
        exit 0
      '');
      ExecStart = toString (pkgs.writeShellScript "gammastep-start" ''
        exec ${pkgs.gammastep}/bin/gammastep \
          -l geoclue2 \
          -t ${toString dayTemperature}:${toString nightTemperature} \
          -b 1.0:0.8 \
          -m wayland
      '');
      Restart = "always";
      RestartSec = 3;
    };
  };
}
