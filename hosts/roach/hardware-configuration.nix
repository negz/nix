{ config, lib, pkgs, modulesPath, ... }:

{

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };


  systemd = {
    mounts = [
      {
        description = "Media for Plex";
        where = "/media";
        what = "/dev/disk/by-uuid/62DE-3E98";
        type = "exfat";
        options = "nowait,uid=193,gid=193";  # Plex Media Server runs as uid 193 https://github.com/NixOS/nixpkgs/blob/release-22.05/nixos/modules/misc/ids.nix#L228
        wantedBy = [ "multi-user.target" ];
        mountConfig = {
          TimeoutSec = "10s";
        };
      }
    ];
    automounts = [
      {
        description = "Media for Plex";
        where = "/mnt/media";
        wantedBy = [ "multi-user.target" ];
      }
    ];
  };

  networking.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
