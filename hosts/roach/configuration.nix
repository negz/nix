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

    # Use systemd-networkd instead of the default scripted networking (dhcpcd).
    # dhcpcd resets net.ipv6.conf.enp3s0f0.accept_ra to 0 on every link event,
    # breaking IPv6 RA acceptance that openthread-border-router depends on.
    useNetworkd = true;
    useDHCP = false;

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
      package = pkgs.unstable.zwave-js-ui;
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

    openthread-border-router = {
      enable = true;
      package = pkgs.unstable.openthread-border-router;
      backboneInterfaces = [ "enp3s0f0" ];
      radio = {
        device = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_14C19FC4D3AC-if00";
        baudRate = 460800;
        flowControl = true;
      };
      web.enable = true;
    };

    caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-vNSHU7txQLs0m0UChuszURXjEoMj4r1902+1ei0/DaI=";
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
      virtualHosts."esphome.i.rk0n.org" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            propagation_delay 30s
          }
          reverse_proxy localhost:6052
        '';
      };
      virtualHosts."thread.i.rk0n.org" = {
        extraConfig = ''
          tls {
            dns cloudflare {env.CF_API_TOKEN}
            propagation_delay 30s
          }
          reverse_proxy localhost:8082
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

    oci-containers.containers.esphome = {
      image = "ghcr.io/esphome/esphome:2026.4.5";
      volumes = [
        "/var/lib/esphome:/config"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "America/Los_Angeles";
        ESPHOME_DASHBOARD_USE_PING = "true";
      };
      extraOptions = [
        "--network=host"
      ];
    };

    oci-containers.containers.home-assistant = {
      image = "ghcr.io/home-assistant/home-assistant:2026.6.0";
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
    network = {
      enable = true;

      networks."40-enp3s0f0" = {
        matchConfig.Name = "enp3s0f0";

        networkConfig = {
          DHCP = "ipv4";

          # Leave IPv6 RA handling to the kernel, not networkd. openthread-border-router
          # sets net.ipv6.conf.enp3s0f0.accept_ra=2 and accept_ra_rt_info_max_plen=64 so
          # the kernel installs the Thread mesh route (fd00:.../64) from the RAs OTBR
          # advertises on this backbone interface. networkd's IPv6AcceptRA= runs a
          # userspace RA client that *disables* the kernel implementation and ignores
          # accept_ra_rt_info_max_plen, which breaks OTBR's backbone routing. Setting
          # this false keeps the kernel RA path (and OTBR's sysctls) authoritative.
          IPv6AcceptRA = false;
        };

        linkConfig.RequiredForOnline = "routable";
      };
    };

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
