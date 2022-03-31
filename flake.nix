{
  description = "A NixOS configuration for a minimal aarch64 qemu VM";

  inputs = {
    darwin = { 
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    hm-darwin = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    nixos = {
      url = "github:nixos/nixpkgs/nixos-21.11";
    };
    hm-nixos = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, darwin, nixos, hm-darwin, hm-nixos }: {
    darwinConfigurations = {
      bugg = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/bugg/configuration.nix
          hm-darwin.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.negz = import ./users/negz/configuration.nix;
          }
        ];
      };
    };
    nixosConfigurations = {
      mael = nixos.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/mael/configuration.nix
          hm-nixos.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.negz = import ./users/negz/configuration.nix;
          }
        ];
      };
    };
  };
}