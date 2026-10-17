# Program modules: shells, dconf, KDE connect, GPG agent, misc tools.
{ config, lib, pkgs, ... }:

{
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;
  programs.kdeconnect.enable = true;
  # NOTE: programs.ssh.startAgent is deliberately absent. Enabling GNOME also
  # enables services.gnome.gcr-ssh-agent, and the module system rejects both at
  # once ("only one SSH agent can be installed at a time"). GnuPG's SSH support
  # is enabled below and takes over the agent socket.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # plasma6.nix and xfce.nix each set pinentryPackage at equal priority
    # (pinentry-qt vs pinentry-gnome3), which is a unique-option conflict when
    # both desktops are enabled. Plasma is the primary session, so it wins.
    pinentryPackage = lib.mkForce pkgs.pinentry-qt;
  };
  programs.obs-studio.enable = true;
  programs.partition-manager.enable = true;
  programs.mtr.enable = true;
}
