{ config, pkgs, ... }:

{
  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc.automatic = true;
  };

  environment.systemPackages = [ pkgs.qemu ];

  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
  };

  programs.zsh.enable = true;

  users = {
    users.negz = {
      home = "/Users/negz";
      shell = pkgs.zsh;
    };
  };

  system.stateVersion = 4;
}
