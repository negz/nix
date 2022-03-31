{ config, lib, pkgs, ... }:

{
  home = {
    enableNixpkgsReleaseCheck = true;

    sessionVariables = {
      EDITOR = "vim";
    };

    shellAliases = {
      rmd = "rm -rf";
      psa = "ps aux";
      l = "ls -F";
      t = "tmux attach-session -t0||tmux";
    };

    packages = [
      pkgs.docker
      pkgs.kubectl
      pkgs.kind
      pkgs.qemu # TODO(negz): From master.
    ];

    sessionPath = [ "$HOME/control/go/bin" ];

    stateVersion = "21.11";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    defaultKeymap = "emacs";
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./zsh;
        file = "p10k.zsh";
     }
    ];

    localVariables = {
      ZSH_AUTOSUGGEST_STRATEGY = ["history" "completion"];
    };

    initExtraBeforeCompInit = ''
      P10KP="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"; [[ ! -r "$P10KP" ]] || source "$P10KP"
    '';
  };

  # TODO(negz): Configure me.
  programs.tmux = {
    enable = true;
  };

  # TODO(negz): Configure me.
  programs.vim = {
    enable = true;
  };

  programs.go = {
    enable = true;
    package = pkgs.go;
    goPath = "control/go";
    goBin = "control/go/bin";
  };
}