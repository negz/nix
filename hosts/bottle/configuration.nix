{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  # TUIs and Tailscale reach the opencode server on loopback.
  opencode-port = "4096";

  # Kept out of this public repo. The server and its clients both read it.
  opencode-password-file = "$HOME/secret/opencode-server-password";
in
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

    # Keep dhcpcd off Docker's interfaces. Otherwise it assigns them IPv4LL
    # addresses and a 169.254.0.0/16 route that hijacks traffic to GCE's
    # metadata DNS server at 169.254.169.254, breaking DNS.
    dhcpcd.denyInterfaces = [
      "veth*"
      "docker*"
      "br-*"
    ];

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
      # Start my user services, like the opencode server, at boot rather than
      # at login.
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

  # The opencode server listens on loopback, and Tailscale serves it to the
  # tailnet over HTTPS at https://bottle.<tailnet>.ts.net, which gets the web
  # UI. It needs HTTPS certificates enabled for the tailnet.
  systemd.services.tailscale-serve-opencode = {
    description = "Serve opencode to the tailnet over HTTPS";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --yes --https=443 http://127.0.0.1:${opencode-port}";
      ExecStop = "${config.services.tailscale.package}/bin/tailscale serve --yes --https=443 off";
      # tailscaled reports ready before it can serve, so retry until it can.
      Restart = "on-failure";
      RestartSec = "5s";
      # The serve command waits for HTTPS certificates to be enabled for the
      # tailnet. Don't hold up boot waiting.
      TimeoutStartSec = "30s";
    };
  };

  home-manager.users.negz = {
    # One opencode server for every TUI (see the oc alias) and the web UI, so
    # agents keep running when I disconnect, and a session started anywhere
    # shows up everywhere.
    systemd.user.services.opencode = {
      Unit = {
        Description = "opencode server";
        # The server loads config and skills once and keeps them until it
        # exits, so restart it when they change. That interrupts any running
        # sessions.
        X-Restart-Triggers = map (f: "${config.home-manager.users.negz.xdg.configFile.${f}.source}") [
          "opencode/opencode.json"
          "opencode/skills"
        ];
      };
      Service = {
        # Agents' tools run with the server's environment, not the attached
        # TUI's. Running under zsh gives the server the same environment as a
        # terminal.
        ExecStart = pkgs.writeScript "opencode-serve" ''
          #!${pkgs.zsh}/bin/zsh
          setopt err_exit
          # The server outlives SSH connections, so it can't use the agent
          # socket any one of them forwards. See ~/.ssh/rc.
          export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
          # Without a password the server makes up one that TUIs and the web UI
          # don't know, so fail rather than start without one.
          OPENCODE_PASSWORD=$(<${opencode-password-file})
          export OPENCODE_PASSWORD=''${OPENCODE_PASSWORD:?is empty}
          exec ${pkgs.unstable.opencode}/bin/opencode serve --port ${opencode-port}
        '';
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };

    # sshd runs this on each new connection. Point a stable path at the agent
    # it forwards, for the opencode server. Connections without a forwarded
    # agent leave it alone.
    home.file.".ssh/rc".text = ''
      if [ -n "$SSH_AUTH_SOCK" ]; then
        ln -sfn "$SSH_AUTH_SOCK" ~/.ssh/agent.sock
      fi
    '';

    # Run a TUI against the opencode server, in the current directory. Without
    # --server the TUI uses opencode's own background server rather than this
    # one.
    home.shellAliases.oc = "OPENCODE_PASSWORD=$(<${opencode-password-file}) opencode --server http://127.0.0.1:${opencode-port}";
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ pkgs.ghostty.terminfo ];
  };
}
