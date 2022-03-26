{
  description = "A NixOS configuration for a minimal aarch64 qemu VM";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-21.11";
    };
    darwin = { 
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    home-manager = {
       url = "github:nix-community/home-manager";
     };
  };

  outputs = { self, darwin, nixpkgs, home-manager }: {
    darwinConfigurations = {
      bugg = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/bugg/configuration.nix
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.negz = import ./users/negz/configuration.nix;
          }
        ];
      };
    };
    nixosConfigurations = {
      mael = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/mael/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.negz = import ./users/negz/configuration.nix;
          }
        ];
      };
    };
  };
}