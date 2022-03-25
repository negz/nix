{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.vim ];

  services.nix-daemon.enable = true;
  nix.package = pkgs.nixUnstable;

  programs.zsh.enable = true; 

  system.stateVersion = 4;
}
