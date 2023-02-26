{ config, pkgs, ... }:

{
  services.nix-daemon.enable = true;

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
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
  };

  programs.zsh.enable = true;

  users = {
    users.negz = {
      # This will typically be the first user's UID. See corresponding note on
      # users.users.negz in hosts/mael/configuration.nix.
      uid = 501;
      home = "/Users/negz";
      shell = pkgs.zsh;
    };
  };

  system.stateVersion = 4;
}
