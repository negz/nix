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

  # We're making an attempt to align our UID and GID with our host so that we
  # appear to be the same user when interacting with our 9p filesystem. The
  # first user on MacOS is typically UID 501, GID 20. GID 20 corresponds to the
  # group 'staff'. On our guest GID 20 is 'lp' (printer access). We don't need
  # that so we overwrite it to 'staff'.
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      staff.gid = 20;
      lp.gid = 21;
    };
    users.negz = {
      uid = 501;
      home = "/home/negz";
      shell = pkgs.zsh;
      isNormalUser = true;
      hashedPassword = "";
      extraGroups = [ "wheel" "docker" "staff" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW8JjnxKQsDA/y88lkCr6/Z0nxp4/veNdZ0f/hB9qHR"
      ];
    };
  };

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
