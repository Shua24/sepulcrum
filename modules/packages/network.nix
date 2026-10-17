# Network stacks, VPNs, remote access.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- network
    networkmanager
    networkmanager-openvpn
    networkmanagerapplet
    iwd
    wpa_supplicant
    dnsmasq
    xl2tpd
    openvpn
    wireguard-tools
    nssmdns
    openssh
    mosh
    valkey
    mailutils
  
]
