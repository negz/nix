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
      dates = "weekly";
      options = "--delete-older-than 7d";
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
      systemd-boot.enable = true;
      # Boot from the ESP's fallback path rather than a UEFI boot entry, so
      # booting doesn't depend on nixos-anywhere's installer or GCE writing and
      # keeping one.
      efi.canTouchEfiVariables = false;
    };

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
    hostName = "bottle";
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [
        config.services.tailscale.port
      ];
      trustedInterfaces = [ "tailscale0" ];
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
      # Start my user services, like Paseo, at boot rather than at login.
      linger = true;
    };
  };

  system.stateVersion = "26.05";

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    tailscale = {
      enable = true;
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

  # Paseo listens on loopback, and Tailscale serves it to the tailnet over
  # HTTPS at https://bottle.<tailnet>.ts.net. Tailscale keeps the serve config
  # in its own state, so this only needs to succeed once, but declaring it
  # means a rebuilt bottle gets it too. It needs HTTPS certificates enabled for
  # the tailnet.
  systemd.services.tailscale-serve-paseo = {
    description = "Serve Paseo to the tailnet over HTTPS";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=443 http://127.0.0.1:6767";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --yes --https=443 off";
      # Don't hold up boot if Tailscale can't serve yet, e.g. before it's
      # logged in.
      TimeoutStartSec = "30s";
    };
  };

  home-manager.users.negz.systemd.user.services.paseo = {
    Unit.Description = "Paseo daemon";
    Service = {
      # Source my session variables so agents Paseo starts get the same
      # environment as agents started from a terminal.
      ExecStart = toString [
        "${pkgs.bash}/bin/bash"
        "-c"
        "'. ${config.home-manager.users.negz.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh && exec ${pkgs.unstable.paseo}/bin/paseo daemon run'"
      ];
      # PASEO_PASSWORD, kept out of this public repo.
      EnvironmentFile = "%h/secret/paseo.env";
      Environment = [
        "PASEO_LISTEN=127.0.0.1:6767"
        "PASEO_HOSTNAMES=bottle.stalk-company.ts.net"
        "PASEO_RELAY_ENABLED=false"
        "PASEO_WEB_UI_ENABLED=true"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ pkgs.ghostty.terminfo ];
  };
}
