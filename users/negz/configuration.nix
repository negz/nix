{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    enableNixpkgsReleaseCheck = true;

    sessionVariables = {
      EDITOR = "nvim";
      TMPDIR = "/tmp"; # Prevent nix-shell from using $XDG_RUNTIME_DIR.
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    shellAliases = {
      rmd = "rm -rf";
      psa = "ps aux";
      l = "eza --classify=auto";
      t = "tmux attach-session";
      view = "nvim -R"; # programs.neovim can't symlink this.
      k = "kubectl";
      fixssh = "eval $(tmux showenv -s SSH_AUTH_SOCK)";
    };

    packages = [
      # Go things
      pkgs.unstable.golangci-lint
      pkgs.go-outline
      pkgs.gcc # For cgo

      # For crossplane/crossplane build
      pkgs.unstable.earthly

      # Things https://github.com/crossplane/build needs
      pkgs.gnumake
      pkgs.perl

      # Kubernetes tools
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.kind

      # Tools I find handy to have around.
      pkgs.file
    ];

    file = {
      hushlogin = {
        target = ".hushlogin";
        text = "";
      };
    };

    sessionPath = [
      "$HOME/bin"
      "$HOME/control/go/bin"
    ];

    stateVersion = "21.11";
  };

  xdg = {
    configFile = {
      "ghostty/config" = {
        text = ''
          theme = light:GitHub-Light-Default,dark:GitHub-Dark-Default
          font-family = Menlo
          font-size = 12
          macos-option-as-alt = true
          link-url = true
        '';
      };
    };
  };

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      history.path = "${config.xdg.dataHome}/zsh/zsh_history";
      enableCompletion = true;
      autosuggestion = {
        enable = true;
      };
      syntaxHighlighting = {
        enable = true;
      };
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
        {
          name = "ghostty-integration";
          src = lib.cleanSource ./zsh;
          file = "ghostty.zsh";
        }
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = "Z6EYQdasvpl1P78poj9efnnLj7QQg13Me8x1Ryyw+dM=";
          };
        }
      ];
      localVariables = {
        ZSH_AUTOSUGGEST_STRATEGY = [
          "history"
          "completion"
        ];
      };
      initExtraBeforeCompInit = ''
        P10KP="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"; [[ ! -r "$P10KP" ]] || source "$P10KP"
      '';
    };

    tmux = {
      enable = true;
      prefix = "C-a";
      terminal = "tmux-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      escapeTime = 0;
      newSession = true;
      extraConfig = ''
        set -g renumber-windows on
        set -g visual-bell on
        set -g mouse on
        set -g status-interval 1
        set -g status-justify left
        set -g status-style fg=default,bg=default
        set -g status-left ' '
        set -g status-left-length 0
        set -g status-right ' '
        set -g status-right-length 0
        set -g pane-active-border-style fg=#58a6ff

        set-window-option -g aggressive-resize
        set-window-option -g window-status-current-style 'bold bg=#cce4ff fg=#000000'
        set-window-option -g window-status-current-format '#I #W '
        set-window-option -g window-status-format '#I #W '
        set-window-option -g message-style 'bold bg=#cce4ff fg=#000000'

        unbind -Tcopy-mode-vi Enter
        unbind '"'
        unbind %

        bind-key A command-prompt 'rename-window "%%"'
        bind-key m run 'tmux show -g mouse | grep -q on && T=off || T=on;tmux set -g mouse $T;tmux display "Mouse $T"'
        bind-key -Tcopy-mode-vi 'v' send -X begin-selection
        bind-key | split-window -h
        bind-key - split-window -v
        bind-key C-a last-window
      '';
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages = [
        pkgs.ripgrep
        pkgs.fd
        pkgs.gh
        pkgs.nixfmt-rfc-style

        # Language servers
        pkgs.nil
        pkgs.lua-language-server
        pkgs.golangci-lint-langserver
      ];
      extraConfig = ''
        set hidden
        set cursorline
        set autoindent
        set smartindent
        set showmatch
        set incsearch
        set noerrorbells
        set number
        set numberwidth=4
        set nowrap
        set showcmd
        set scrolloff=3
        set backspace=2
        set textwidth=80
        set formatoptions=cq

        filetype indent on
      '';
      plugins = [
        pkgs.vimPlugins.vim-nix
        pkgs.vimPlugins.vim-visual-multi
        pkgs.vimPlugins.plenary-nvim
        pkgs.vimPlugins.telescope-nvim
        pkgs.vimPlugins.which-key-nvim
        pkgs.unstable.vimPlugins.blink-cmp-git
        pkgs.unstable.vimPlugins.blink-cmp-avante
        {
          plugin = pkgs.vimPlugins.mini-icons;
          type = "lua";
          config = builtins.readFile ./nvim/mini-icons.lua;
        }
        {
          plugin = pkgs.vimPlugins.gitsigns-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/gitsigns.lua;
        }
        {
          plugin = pkgs.vimPlugins.lualine-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/lualine.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.neo-tree-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/neo-tree.lua;
        }
        {
          plugin = pkgs.vimPlugins.barbar-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/barbar.lua;
        }
        {
          plugin = pkgs.vimPlugins.nvim-lspconfig;
          type = "lua";
          config = builtins.readFile ./nvim/lspconfig.lua;
        }
        {
          plugin = pkgs.vimPlugins.lsp-format-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/lspformat.lua;
        }
        {
          plugin = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
          type = "lua";
          config = builtins.readFile ./nvim/treesitter.lua;
        }
        {
          plugin = pkgs.vimPlugins.nvim-treesitter-context;
          type = "lua";
          config = builtins.readFile ./nvim/treesitter-context.lua;
        }
        {
          plugin = pkgs.vimPlugins.codewindow-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/codewindow.lua;
        }
        {
          plugin = pkgs.vimPlugins.vim-illuminate;
          type = "lua";
          config = builtins.readFile ./nvim/illuminate.lua;
        }
        {
          plugin = pkgs.vimPlugins.avante-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/avante.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.blink-cmp;
          type = "lua";
          config = builtins.readFile ./nvim/blink-cmp.lua;
        }
        {
          plugin = pkgs.vimUtils.buildVimPlugin {
            name = "github-nvim-theme";
            src = pkgs.fetchFromGitHub {
              owner = "projekt0n";
              repo = "github-nvim-theme";
              rev = "v1.1.2";
              sha256 = "ur/65NtB8fY0acTUN/Xw9fT813UiL3YcP4+IwkaUzTE=";
            };
          };
          type = "lua";
          config = builtins.readFile ./nvim/github-theme.lua;
        }
        {
          plugin = pkgs.vimUtils.buildVimPlugin {
            name = "colorful-menu";
            src = pkgs.fetchFromGitHub {
              owner = "xzbdmw";
              repo = "colorful-menu.nvim";
              rev = "f80feb8a6706f965321aff24d0ed3849f02a7f77";
              sha256 = "nLrxL/eVELFfqmoT+2qj1yJb4S6DjtCg9b5B9o73RuY=";
            };
          };
          type = "lua";
          config = builtins.readFile ./nvim/colorful-menu.lua;
        }
      ];
    };

    ssh = {
      enable = true;
      forwardAgent = true;

      # ghostty uses its own terminfo, which most hosts won't have
      matchBlocks = {
        "ghostty-terminfo" = {
          host = "!mael,*";
          setEnv = {
            TERM = "xterm-256color";
          };
        };
      };
    };

    git = {
      enable = true;
      userName = "Nic Cope";
      userEmail = "nicc@rk0n.org";
      aliases = {
        b = "branch";
        ca = "commit -a";
        co = "checkout";
        d = "diff";
        p = "status";
        ll = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
      };
      ignores = [
        ".DS_Store"
        "shell.nix"
      ];
      extraConfig = {
        push = {
          default = "current";
        };
        url = {
          "git@github.com:" = {
            insteadOf = "https://github.com/";
          };
        };
      };
    };

    eza = {
      enable = true;
    };

    go = {
      enable = true;
      package = pkgs.unstable.go_1_24;
      goPath = "control/go";
      goBin = "control/go/bin";
      goPrivate = [ "github.com/upbound" ];
    };

    jq = {
      enable = true;
    };
  };
}
