{
  description = "A NixOS configuration for a minimal aarch64 qemu VM";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-21.11"; };
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      mael = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}