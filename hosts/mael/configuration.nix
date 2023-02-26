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

    settings = {
      auto-optimise-store = true;
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
      efi.canTouchEfiVariables = true;
    };
    # Use unstable in order to get the unstable prl-tools.
    kernelPackages = pkgs.unstable.linuxPackages_latest;
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
      checkReversePath = "loose"; # For Tailscale compatibility.
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
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
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
  };

  systemd = {
    user = {
      services = {
        vscode-fix-ssh = {
          description = "Fix Visual Studio Code SSH";
          wantedBy = [ "default.target" ];
          script = ''
            set -euo pipefail
            PATH=${lib.makeBinPath (with pkgs; [ coreutils findutils inotify-tools ])}
            bin_dir=~/.vscode-server/bin
            if [[ -e $bin_dir ]]; then
              find "$bin_dir" -mindepth 2 -maxdepth 2 -name node -exec ln -sfT ${pkgs.nodejs-16_x}/bin/node {} \;
              find "$bin_dir" -path '*/@vscode/ripgrep/bin/rg' -exec ln -sfT ${pkgs.ripgrep}/bin/rg {} \;
            else
              mkdir -p "$bin_dir"
            fi
            while IFS=: read -r bin_dir event; do
              if [[ $event == 'CREATE,ISDIR' ]]; then
                touch "$bin_dir/node"
                inotifywait -qq -e DELETE_SELF "$bin_dir/node"
                ln -sfT ${pkgs.nodejs-16_x}/bin/node "$bin_dir/node"
                ln -sfT ${pkgs.ripgrep}/bin/rg "$bin_dir/node_modules/@vscode/ripgrep/bin/rg"
              elif [[ $event == DELETE_SELF ]]; then
                exit 0
              fi
            done < <(inotifywait -q -m -e CREATE,ISDIR -e DELETE_SELF --format '%w%f:%e' "$bin_dir")
          '';
        };
      };
    };
  };
}
