{ config, pkgs, ... }:

{
  nix = {
    package = pkgs.nixUnstable;
  };

  time.timeZone = "America/Los_Angeles";

  security.sudo.wheelNeedsPassword = false;

  users.mutableUsers = true;

  documentation.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;
  documentation.man.enable = false;

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = true;
  services.openssh.permitRootLogin = "no";
  services.k3s.enable = true;

  networking.hostName = "nix";
  networking.firewall.enable = false;
  networking.interfaces.ens160.useDHCP = true;

  system.stateVersion = "21.11";

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  virtualisation.containerd.enable = true;

  environment.defaultPackages = [ ];
  environment.systemPackages = [ pkgs.k3s pkgs.vim ];
  environment.variables = { EDITOR = "vim"; };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}