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

      # AI things
      pkgs.unstable.claude-code
      pkgs.unstable.nil

      # Useful dependencies for AI tools
      pkgs.gh
      pkgs.ripgrep
      pkgs.unstable.gopls
      pkgs.nur.repos.charmbracelet.crush

      # Tools I find handy to have around.
      pkgs.file
      pkgs.bottom

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
    enable = true;

    configFile = {
      "ghostty/config" = {
        text = ''
          theme = light:GitHub-Light-Default,dark:GitHub-Dark-Default
          font-family = Menlo
          font-size = 12
          macos-option-as-alt = true
          link-url = true
          adjust-cursor-thickness = 100%
        '';
      };
    };

    # For Neovim's dashboard - see nvim/snacks.lua.
    dataFile = {
      "nvim/neovim-mark.png" = {
        source = ./nvim/neovim-mark.png;
      };
    };
  };

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      history.path = "${config.xdg.dataHome}/zsh/zsh_history";
      autosuggestion = {
        enable = true;
        strategy = [
          "history"
          "completion"
        ];
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
      initContent = lib.mkOrder 550 ''
        P10KP="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"; [[ ! -r "$P10KP" ]] || source "$P10KP"
      '';
    };

    carapace = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.unstable.carapace;
    };

    tmux = {
      enable = true;
      package = (pkgs.callPackage ../../pkgs/tmux/package.nix { });
      prefix = "C-a";
      terminal = "tmux-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      escapeTime = 0;
      newSession = true;
      extraConfig = ''
        set -g renumber-windows on
        set -g visual-bell on
        set -g mouse on
        set -g allow-passthrough on

        set -g status-interval 1
        set -g status-justify left
        set -g status-style fg=default,bg=default
        set -g status-left ' '
        set -g status-left-length 0
        set -g status-right ' '
        set -g status-right-length 0

        set -g pane-border-status bottom
        set -g pane-active-border-style fg=default
        set -g pane-border-style fg=#58a6ff
        set -g pane-border-format ' #{?pane_active,#[bold],} #T #[fg=nobold] '
        set -g mode-style "fg=default,bg=default,reverse"

        set-window-option -g aggressive-resize
        set-window-option -g window-status-current-style 'bold bg=default fg=default'
        set-window-option -g window-status-style 'fg=#58a6ff'
        set-window-option -g window-status-current-format '#I #W '
        set-window-option -g window-status-format '#I #W '
        set-window-option -g message-style 'bold bg=#cce4ff fg=#000000'

        unbind -Tcopy-mode-vi Enter
        unbind '"'
        unbind %
        unbind -n MouseDown3Pane

        bind-key A command-prompt 'rename-window "%%"'
        bind-key m run 'tmux show -g mouse | grep -q on && T=off || T=on;tmux set -g mouse $T;tmux display "Mouse $T"'
        bind-key -Tcopy-mode-vi 'v' send -X begin-selection
        bind-key | split-window -h -c "#{pane_current_path}"
        bind-key - split-window -v -c "#{pane_current_path}"
        bind-key C-a last-window
      '';
    };

    neovim = {
      enable = true;
      package = pkgs.unstable.neovim-unwrapped;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      extraPackages = [
        # Nix
        pkgs.nil
        pkgs.nixfmt-rfc-style

        # Lua / NeoVim
        pkgs.lua-language-server
        pkgs.ripgrep
        pkgs.fd

        # Spelling and grammar
        pkgs.unstable.harper
        pkgs.unstable.typos-lsp

        # Go
        pkgs.unstable.gopls
        pkgs.unstable.golangci-lint
        pkgs.unstable.golangci-lint-langserver
        pkgs.gotestsum

        # Python
        pkgs.unstable.basedpyright
        pkgs.unstable.ruff

        # Protobuf
        pkgs.unstable.buf

        # Images
        pkgs.imagemagick
        pkgs.ghostscript_headless
        pkgs.mermaid-cli
        pkgs.chafa

        # Diffs
        pkgs.delta
      ];
      extraConfig = ''
        let mapleader = "\<Space>"

        set hidden
        set cursorline
        set guicursor=i:blinkon100-blinkoff100-blinkwait100-ver10
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
        set sidescroll=3
        set backspace=2
        set textwidth=80
        set formatoptions=cq
        set clipboard+=unnamedplus
        set mousemodel=extend

        filetype indent on
      '';
      plugins = [
        # Intentionally loaded first, to make sure it applies to other plugins.
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
            name = "neominimap";
            src = pkgs.fetchFromGitHub {
              owner = "Isrothy";
              repo = "neominimap.nvim";
              rev = "v3.14.1";
              sha256 = "6us7ykudgnINqQoAURQwOdZ1X3T22YtWxYAme9yGkmo=";
            };
          };
          type = "lua";
          config = builtins.readFile ./nvim/neominimap.lua;
        }
        pkgs.vimPlugins.plenary-nvim
        {
          plugin = pkgs.vimPlugins.mini-icons;
          type = "lua";
          config = builtins.readFile ./nvim/mini-icons.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.snacks-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/snacks.lua;
        }
        {
          plugin = pkgs.vimPlugins.gitsigns-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/gitsigns.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.lualine-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/lualine.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.nvim-lspconfig;
          type = "lua";
          config = builtins.readFile ./nvim/lspconfig.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.nvim-treesitter.withAllGrammars;
          type = "lua";
          config = builtins.readFile ./nvim/treesitter.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.nvim-treesitter-context;
          type = "lua";
          config = builtins.readFile ./nvim/treesitter-context.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.blink-cmp;
          type = "lua";
          config = builtins.readFile ./nvim/blink-cmp.lua;
        }
        {
          plugin = pkgs.vimPlugins.which-key-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/which-key.lua;
        }
        {
          plugin = pkgs.vimPlugins.flash-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/flash.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.render-markdown-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/render-markdown.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.actions-preview-nvim;
          type = "lua";
          config = builtins.readFile ./nvim/actions-preview.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.nvim-bqf;
          type = "lua";
          config = builtins.readFile ./nvim/bqf.lua;
        }
        {
          plugin = pkgs.vimPlugins.neotest;
          type = "lua";
          config = builtins.readFile ./nvim/neotest.lua;
        }
        pkgs.unstable.vimPlugins.neotest-golang
        pkgs.unstable.vimPlugins.neotest-python
        {
          plugin = pkgs.unstable.vimPlugins.nvim-coverage;
          type = "lua";
          config = builtins.readFile ./nvim/coverage.lua;
        }
        {
          plugin = pkgs.unstable.vimPlugins.colorful-menu-nvim;
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
          host = "!mael,!tehol,*";
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
