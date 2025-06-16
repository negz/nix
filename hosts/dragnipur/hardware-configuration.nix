{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  hardware.parallels = {
    enable = true;
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "sr_mod"
  ];
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
