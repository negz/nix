{
  description = "A NixOS configuration for https://github.com/negz's machines";

  inputs = {
    nixpkgs-master = {
      url = "github:nixos/nixpkgs/master";
    };
    nixpkgs-darwin = {
      url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    hm-darwin = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos = {
      url = "github:nixos/nixpkgs/nixos-25.05";
    };
    nixos-unstable = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    hm-nixos = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixos";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    {
      self,
      nixpkgs-master,
      nixpkgs-darwin,
      nixpkgs-unstable,
      darwin,
      hm-darwin,
      nixos,
      nixos-unstable,
      hm-nixos,
      nur,
    }:
    let
      darwin-overlays = [
        # Allow configurations to use pkgs.unstable.<package-name>.
        (final: prev: {
          unstable = import nixpkgs-unstable {
            system = prev.system;
            config.allowUnfree = true;
          };
          master = import nixpkgs-master {
            system = prev.system;
            config.allowUnfree = true;
          };
          nur = import nur {
            pkgs = prev;
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
          master = import nixpkgs-master {
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
        rake = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            { nixpkgs.overlays = darwin-overlays; }
            ./hosts/rake/configuration.nix
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
        dragnipur = nixos.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            { nixpkgs.overlays = nixos-overlays; }
            nur.modules.nixos.default
            ./hosts/dragnipur/configuration.nix
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
        tehol = nixos.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.overlays = nixos-overlays; }
            ./hosts/tehol/configuration.nix
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
