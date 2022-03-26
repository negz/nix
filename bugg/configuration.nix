{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.vim ];

  services.nix-daemon.enable = true;

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc.automatic = true;
  };

  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
  };

  programs.zsh.enable = true; 

  system.stateVersion = 4;
}
