# flake.nix
{
  description = "NixOS configuration for Coolify server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";  # NixOS 24.05 release
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.coolify = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";  # Adjust for your architecture
      modules = [
        ./configuration.nix  # Import the main configuration file
      ];
    };
  };
}
