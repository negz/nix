{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    (modulesPath + "/profiles/minimal.nix")
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
    };

    optimise = {
      automatic = true;
    };

    settings = {
      trusted-users = [ "negz" ];
      max-jobs = "auto";
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
    # kernelPackages = pkgs.unstable.linuxPackages_latest;

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
    hostName = "dragnipur";
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
      extraGroups = [
        "wheel"
        "docker"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW8JjnxKQsDA/y88lkCr6/Z0nxp4/veNdZ0f/hB9qHR"
      ];
    };
  };

  system.stateVersion = "25.05";

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    fstrim.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  programs = {
    zsh.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };

    # For vscode-server - https://nixos.wiki/wiki/Visual_Studio_Code#nix-ld
    # Note that as of NixOS 23.05 the env vars are set magically.
    nix-ld.enable = true;

    nix-index.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
      };
    };
  };

  # TODO: boot.binfmt.emulatedSystems with preferStaticEmulators fails to build
  # on aarch64 due to linker issues (nixpkgs#392673). Replace with native NixOS
  # binfmt config once fixed.
  systemd.additionalUpstreamSystemUnits = [
    "proc-sys-fs-binfmt_misc.automount"
    "proc-sys-fs-binfmt_misc.mount"
  ];
  systemd.services.docker-binfmt = {
    description = "Install QEMU binfmt handlers via Docker";
    after = [ "docker.service" "proc-sys-fs-binfmt_misc.mount" ];
    requires = [ "docker.service" ];
    wants = [ "proc-sys-fs-binfmt_misc.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.docker}/bin/docker run --privileged --rm tonistiigi/binfmt --install all";
    };
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ pkgs.ghostty.terminfo ];
  };
}
