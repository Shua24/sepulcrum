{
  description = "sepulcrum - ASUS ROG Strix G513RM on NixOS unstable";

  inputs = {
    # Floating by decision: flake.lock pins whatever nixos-unstable was at the
    # last `nix flake update`. As of 2026-10-14 that is rev 55bfb4d7, the same
    # revision this machine was installed from, so the first rebuild is not a
    # hidden upgrade.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # `follows` is not optional: without it nixos-hardware drags in its OWN
    # nixpkgs input, giving you two nixpkgs instances in one evaluation.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: {
    nixosConfigurations.sepulcrum = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # configuration.nix reads this argument and falls back to a pinned
      # fetchTarball when it is absent (the non-flake rebuild path).
      specialArgs = { inherit nixos-hardware; };
      modules = [ ./configuration.nix ];
    };
  };
}
