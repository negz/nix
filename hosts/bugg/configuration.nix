{ config, pkgs, ... }:

{
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
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
  };

  programs.zsh.enable = true;

  networking = {
    computerName = "bugg";
    hostName = "bugg";
  };

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
