{
  description = "A NixOS configuration for https://github.com/negz's M1 Mac";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/release-22.05";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hm-darwin = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos = {
      url = "github:nixos/nixpkgs/nixos-22.05";
    };
    nixos-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    hm-nixos = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, hm-darwin, nixos, nixos-unstable, hm-nixos }:
    let
      darwin-overlays = [
        # Allow configurations to use pkgs.unstable.<package-name>.
        (final: prev: {
          unstable = import nixpkgs-unstable {
            system = prev.system;
            config.allowUnfree = true;
          };
        })
      ];
      nixos-overlays = [
        # Allow configurations to use pkgs.unstable.<package-name>.
        (final: prev: {
          unstable = import nixos-unstable {
            system = prev.system;
            config.allowUnfree = true;
          };
        })
      ];
    in
    {
      darwinConfigurations = {
        bugg = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { nixpkgs.overlays = darwin-overlays; }
            ./hosts/bugg/configuration.nix
            hm-darwin.darwinModules.home-manager
            {
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
            { nixpkgs.overlays = nixos-overlays; }
            ./hosts/mael/configuration.nix
            hm-nixos.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.negz = import ./users/negz/configuration.nix;
            }
          ];
        };
        roach = nixos.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.overlays = nixos-overlays; }
            ./hosts/roach/configuration.nix
            hm-nixos.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.negz = import ./users/negz/configuration.nix;
            }
          ];
        };
      };
    };
}
