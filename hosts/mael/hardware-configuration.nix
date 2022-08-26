{ config, lib, pkgs, modulesPath, ... }:

{

  imports = [ ../../modules/parallels-guest.nix ];

  # TODO(negz): Use upstream module once the below PR makes it into a release.
  # https://github.com/NixOS/nixpkgs/pull/179582
  disabledModules = [ "virtualisation/parallels-guest.nix" ];
  hardware.parallels = {
    enable = true;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
}
