# Compilers, language runtimes and build tooling.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- development
    gcc
    clang
    gnumake
    cmake
    meson
    ninja
    pkg-config
    cmocka
    php
    phpPackages.composer
    python3
    python3Packages.pip
    python3Packages.defusedxml
    python3Packages.packaging
    python3Packages.qrcode
    python3Packages.ipython
    uv
    nodejs_22
    pnpm
    yarn
    corepack
    go
    rustc
    cargo
    rustup
    jdk21
    gradle
    maven
    dotnet-sdk_10
    dotnet-aspnetcore_10
    gnat15
    gnat15Packages.gprbuild
    alire
    opencode
  
]
