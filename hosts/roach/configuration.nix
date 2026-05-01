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
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "roach";
    search = [ "i.rk0n.org" ];
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        443
      ];
    };
  };

  time.timeZone = "America/Los_Angeles";

  security.sudo.wheelNeedsPassword = false;

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

  system.stateVersion = "21.11";

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    plex = {
      enable = true;
      package = pkgs.unstable.plex;
      openFirewall = true;
    };

    zwave-js-ui = {
      enable = true;
      serialPort = "/dev/serial/by-id/usb-Nabu_Casa_ZWA-2_1CDBD4AE1ABC-if00";
      settings = {
        TRUST_PROXY = "loopback";
        ZWAVE_PORT = "/dev/serial/by-id/usb-Nabu_Casa_ZWA-2_1CDBD4AE1ABC-if00";
        TZ = "America/Los_Angeles";
      };
    };

    matter-server = {
      enable = true;
    };

    caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        # Build once on roach to get the correct hash.
        hash = "sha256-4WF7tIx8d6O/Bd0q9GhMch8lS3nlR5N3Zg4ApA3hrKw=";
      };
      virtualHosts."home.i.rk0n.org" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            propagation_delay 30s
          }
          reverse_proxy localhost:8123
        '';
      };
      virtualHosts."zwave.i.rk0n.org" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            propagation_delay 30s
          }
          reverse_proxy localhost:8091
        '';
      };
      virtualHosts."plex.i.rk0n.org" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            propagation_delay 30s
          }
          reverse_proxy localhost:32400
        '';
      };
    };
  };

  programs = {
    zsh.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
      };
    };

    oci-containers.containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:2026.4.4";
      volumes = [
        "/var/lib/hass:/config"
        "/etc/localtime:/etc/localtime:ro"
        "/run/dbus:/run/dbus"
      ];
      environment = {
        TZ = "America/Los_Angeles";
      };
      extraOptions = [
        "--network=host"
        # Required for Bluetooth (BLE scanning and adapter management).
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };
  };

  environment = {
    defaultPackages = lib.mkForce [ ];
    systemPackages = [ pkgs.ghostty.terminfo ];
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = "/etc/caddy/env";

  systemd = {
    mounts = [
      {
        description = "Media for Plex";
        where = "/media";
        what = "/dev/disk/by-uuid/62DE-3E98";
        type = "exfat";
        options = "nofail,uid=193,gid=193"; # Plex Media Server runs as uid 193 https://github.com/NixOS/nixpkgs/blob/release-22.05/nixos/modules/misc/ids.nix#L228
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

}
