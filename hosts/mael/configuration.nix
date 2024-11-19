{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      (modulesPath + "/profiles/minimal.nix")
    ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
    };

    optimise = {
      automatic = true;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };

    # To get the latest prltools package we need to the latest kernel.
    kernelPackages = pkgs.unstable.linuxPackages_latest;

    kernel = {
      sysctl = {
        # To resolve "too many open files" issues in kind pods
        # https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files
        "fs.inotify.max_user_watches" = "524288";
        "fs.inotify.max_user_instances" = "512";
      };
    };
  };


  networking = {
    hostName = "mael";
    search = [ "v.rk0n.org" ];
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "America/Los_Angeles";

  security = {
    sudo = {
      wheelNeedsPassword = false;
    };

    pam = {
      loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "4096";
        }
      ];
    };

  };

  users = {
    mutableUsers = false;
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

  system.stateVersion = "21.11";

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };

  programs = {
    zsh.enable = true;
    vim.defaultEditor = true;

    # For vscode-server - https://nixos.wiki/wiki/Visual_Studio_Code#nix-ld
    # Note that as of NixOS 23.05 the env vars are set magically.
    nix-ld.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      package = pkgs.unstable.docker_26;
      autoPrune = {
        enable = true;
      };
    };
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
  };
}
