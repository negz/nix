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

  time.timeZone = "America/Los_Angeles";

  programs.zsh.enable = true; 

  system = {
    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyleSwitchesAutomatically = true;
        NSNavPanelExpandedStateForSaveMode = true;
      };
      dock = {
        orientation = "right";
        show-recents = false;
        minimize-to-application = true;
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
      alf.allowdownloadsignedenabled = 1;
      finder.CreateDesktop = false;
    };
  };

  system.stateVersion = 4;
}
