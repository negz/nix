{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      (modulesPath + "/profiles/minimal.nix")
    ];


  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
    gc.automatic = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "mael";
    search = [ "v.rk0n.org" ];
    useDHCP = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  time.timeZone = "America/Los_Angeles";

  security.sudo.wheelNeedsPassword = false;

  users = {
    defaultUserShell = pkgs.zsh;
    users.negz = {
      home = "/home/negz";
      shell = pkgs.zsh;
      isNormalUser = true;
      hashedPassword = "";
      extraGroups = [ "wheel" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW8JjnxKQsDA/y88lkCr6/Z0nxp4/veNdZ0f/hB9qHR"
      ];
    };
  };

  # Use a systemd mount because it will automatically create the mountpoint.
  # TODO(negz): Allow config.users.users.negz.uid access, which will likely
  # require setting users.users.negz.uid explicitly.
  systemd.mounts = [
    {
      description = "/Users/negz from QEMU host";
      where = "/Users/negz";
      what = "/Users/negz";
      type = "9p";
      options = "trans=virtio,version=9p2000.L,msize=512000,cache=mmap";
    }
  ];

  system.stateVersion = "21.11";

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };
    tailscale.enable = true;
  };

  programs = {
    zsh.enable = true;
    vim.defaultEditor = true;
  };

  virtualisation = {
    docker.enable = true;
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ pkgs.tailscale ];
  };
}
