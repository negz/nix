{
  description = "A NixOS configuration for a minimal aarch64 qemu VM";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-21.11";
    };
    darwin = { 
      url = "github:lnl7/nix-darwin/master";
      nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, darwin, nixpkgs }: {
    darwinConfigurations = {
      bugg = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./bugg/configuration.nix ];
      };
    };
    nixosConfigurations = {
      mael = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [ ./mael/configuration.nix ];
      };
    };
  };
}