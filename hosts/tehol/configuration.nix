{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
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
      timeout = 0;
    };

    kernelPackages = pkgs.unstable.linuxPackages_latest;

    plymouth = {
      enable = true;
      theme = "loader_2";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ "loader_2" ];
        })
      ];
    };

    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
  };

  hardware = {
    nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      nvidiaSettings = true;
    };

    xpadneo = {
      enable = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  networking = {
    hostName = "tehol";
    search = [ "i.rk0n.org" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        3389
      ];
      allowedUDPPorts = [ 3389 ];
    };

    networkmanager = {
      enable = true;
    };
  };

  time.timeZone = "America/Los_Angeles";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  security = {
    sudo = {
      wheelNeedsPassword = false;
    };

    rtkit.enable = true;
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users.negz = {
      home = "/home/negz";
      shell = pkgs.zsh;
      isNormalUser = true;
      hashedPassword = "";
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOW8JjnxKQsDA/y88lkCr6/Z0nxp4/veNdZ0f/hB9qHR"
      ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };

      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;

      videoDrivers = [ "nvidia" ];
    };

    printing.enable = true;

    # Sound stuff
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Needed by Pipewire
    pulseaudio.enable = false;
  };

  programs = {
    zsh.enable = true;

    # Maybe useful for gaming stuff?
    # Note that as of NixOS 23.05 the env vars are set magically.
    nix-ld.enable = true;

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };

    gamemode.enable = true;

    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "negz" ];
    };
  };

    systemPackages = [
      pkgs.ghostty.terminfo

      pkgs.google-chrome
      pkgs.mangohud
      pkgs.protonup
      pkgs.lutris
      pkgs.heroic
      pkgs.bottles

      pkgs.gnomeExtensions.freon
      pkgs.gnomeExtensions.blur-my-shell
      pkgs.gnomeExtensions.night-theme-switcher
      pkgs.gnomeExtensions.just-perfection
    ];

    gnome = {
      excludePackages = [
        pkgs.gnome-tour
        pkgs.epiphany
        pkgs.geary
        pkgs.gnome-music
        pkgs.cheese
        pkgs.tali
        pkgs.iagno
        pkgs.hitori
        pkgs.atomix
        pkgs.gnome-maps
        pkgs.gnome-contacts
      ];
    };

    etc = {
      # TODO(negz): Make this work? Right now it'll connect but just gives
      # a black screen. Can't figure out why.
      "gnome-remote-desktop/grd.conf" = {
        user = "gnome-remote-desktop";
        group = "gnome-remote-desktop";
        mode = "0644";
        text = ''
          [RDP]
          enabled=true
          port=3389

          # TODO(negz): Generate these with ACME?
          # These were generated using this command from the freerdp package:
          # winpr-makecert -silent -rdp -path ~gnome-remote-desktop rdp-tls
          tls-key=/var/lib/gnome-remote-desktop/rdp-tls.key
          tls-cert=/var/lib/gnome-remote-desktop/rdp-tls.crt
        '';
      };
    };
  };

  systemd = {
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };

    services = {
      # GNOME installs this but doesn't enable it.
      gnome-remote-desktop = {
        enable = true;
        wantedBy = [ "graphical.target" ];
      };
    };
  };

  system.stateVersion = "24.05";
}
