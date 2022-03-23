{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      (modulesPath + "/profiles/minimal.nix") 
    ];


  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
    gc.automatic = true;
  };

  nixpkgs = {
    config.allowUnfree = true;
    config.allowUnsupportedSystem = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "mael";
    search = [ "v.rk0n.org" ];
    useDHCP = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  time.timeZone = "America/Los_Angeles";

  security.sudo.wheelNeedsPassword = false;

  users = {
    defaultUserShell = pkgs.zsh;
    users.negz = {
      isNormalUser = true;
      extraGroups = [ "wheel", "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEnexRk7YdGNbOOKgZQSzL1/x84/1NNl8m/oWWCjCk2xYZAr8iBFPtFFEWPrdJ+OEJjGrInhqJBkICoF0R4rsHojDMwukbuJT9sFXBzpNwkaP+DPgFzao7FYNoAb555f+JmGEXqvSJTs3crmYQdS09Yy4HqMgCUuYIA987kWQ8LT068pphQTCAX0WyRg7pNF2GSuW6EnGJYJBo081/AVoGuWuF+ciIAN0/q1YcPbQoTPa+Hiu/jLo7rMXeU+PjX4v+fH22kcuQDR6APpOqmB7b9opTOBepy1tDogJwYQNCpFW/gQMsbWcj9kxRe/hNoyCi20iFnJOXQzP393kfEGT5tllYHDpRCaVUUMREtF630A+IAZASRDiAZq/oLZK1mLhwM9KOu4BYBmt0glxLZXt6dsgUD4y7KrLLghrXBXi+aNP4sKKeFzIGH5P1ZqL9dAAAVdjr+yRYIWw0XGVG9FE4qlOfzXtc9e/v2IIubzjx/Cu5LgzakPTaDgDa/nUaIQDCDS95bNa8t/nh1/rLqI/qb3mSKFlY0Z5aDyTjIxDmwuwQQa04zmDKUjgDaZKwoo8gQMVVU5g2fyrC+xK21exffAcPtguIr0x7Z5aeY1dekNESHsaMwzOWLJowIHIWKRLyMlUiuoXmh/FGwWTauSmFF9XJ9GikzT9X9Sz1cIxwMQ== negz@rk0n.org"
      ];
    };
  };

  system.stateVersion = "21.11";

  services = {
    openssh.enable = true;
    openssh.permitRootLogin = "no";
    openssh.passwordAuthentication = false;
    tailscale.enable = true;
  };

  programs = {
    zsh.enable = true;
    vim.defaultEditor = true;
  };

  virtualisation = {
    docker.enable = true;
  };

  environment = {
    defaultPackages = lib.mkForce [];
    systemPackages = [ pkgs.tailscale ];
  };

  documentation = {
    enable = true;
    nixos.enable = true;
    man.enable = true;
  };
}
