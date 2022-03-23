{
  description = "A NixOS configuration for a minimal aarch64 qemu VM";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
  };

  outputs = inputs:
  {
    nixosConfigurations = {

      mael = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}