{ config, lib, pkgs, ... }:

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
      # Language servers
      pkgs.nil
      pkgs.gopls

      # Go things
      pkgs.golangci-lint
      pkgs.go-outline
      pkgs.gcc # Gor cgo

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

    sessionPath = [ "$HOME/bin" "$HOME/control/go/bin" ];

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
        ZSH_AUTOSUGGEST_STRATEGY = [ "history" "completion" ];
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
      extraPackages = [ pkgs.ripgrep pkgs.fd ]; # For Telescope
      extraConfig = ''
        set hidden
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
      '';
      plugins = with pkgs.vimPlugins;
        [
          vim-nix
          vim-visual-multi
          plenary-nvim
          {
            plugin = gitsigns-nvim;
            config = ''
              lua << END
              require('gitsigns').setup()
              END
            '';
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
            config = ''
              lua << END
              require('github-theme').setup {
                vim.api.nvim_create_autocmd("OptionSet", {
                  pattern = "background",
                  callback = function()
                    if vim.o.background == "light" then
                      vim.cmd.colorscheme("github_light_default")
                    end
                    if vim.o.background == "dark" then
                      vim.cmd.colorscheme("github_dark_default")
                    end
                  end,
                })
              }
              END
            '';
          }
          {
            plugin = nvim-web-devicons;
          }
          {
            plugin = lualine-nvim;
            config = ''
              lua << END
              require('lualine').setup {
                options = {
                  icons_enabled = true,
                  section_separators = ' ',
                  component_separators = ' ',
                  globalstatus = true
                }
              }
              END
            '';
          }
          {
            plugin = pkgs.unstable.vimPlugins.neo-tree-nvim;
            config = ''
              lua << END
              require('neo-tree').setup {
                vim.api.nvim_create_autocmd("UiEnter", {
                  callback = function()
                    vim.cmd.Neotree("toggle", "action=show")
                  end,
                }),

                close_if_last_window = true,
                filesystem = {
                  filtered_items = {
                    visible = true,
                  },
                  hijack_netrw_behavior = "open_default",
                  window = {
                    position = "right",
                    width = 35,
                  },
                  follow_current_file = {
                    enabled = true,
                    leave_dirs_open = true,
                  }
                }
              }
              END
            '';
          }
          {
            plugin = barbar-nvim;
            config = ''
              lua << END
              require('barbar').setup()
              END
            '';
          }
          {
            plugin = nvim-lspconfig;
            config = ''
              lua << END
              require('lspconfig').gopls.setup {}
              END
            '';
          }
          {
            plugin = lspkind-nvim;
            config = ''
              lua << END
              require('lspkind').setup()
              END
            '';
          }
          {
            plugin = nvim-treesitter.withAllGrammars;
            config = ''
              lua << END
              require('nvim-treesitter.configs').setup {
                highlight = { enable = true },
                indent = { enable = true },
                textobjects = {
                  select = {
                    enable = true,
                    lookahead = true
                  }
                }
              }
              END
            '';
          }
          {
            plugin = nvim-treesitter-context;
            config = ''
              lua << END
              require('treesitter-context').setup()
              END
            '';
          }
          {
            plugin = telescope-nvim;
            config = ''
              lua << END
              local builtin = require('telescope.builtin')
              vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
              vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
              END
            '';
          }
          {
            plugin = codewindow-nvim;
            config = ''
              lua << END
              require('codewindow').setup {
                auto_enable = true,
                show_cursor = false,
                window_border = 'none',
                minimap_width = 15,
                screen_bounds = 'background'
              }
              END
            '';
          }
          {
            plugin = pkgs.vimUtils.buildVimPlugin {
              name = "guihua";
              src = pkgs.fetchFromGitHub {
                owner = "ray-x";
                repo = "guihua.lua";
                rev = "d783191eaa75215beae0c80319fcce5e6b3beeda";
                sha256 = "XpUsbj1boDfbyE8C6SdOvZdkd97682VVC81fvQ5WA/4=";
              };
            };
          }
          {
            plugin = go-nvim;
            config = ''
              lua << END
              require('go').setup()

              local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
              vim.api.nvim_create_autocmd("BufWritePre", {
                pattern = "*.go",
                callback = function()
                  require('go.format').goimports()
                end,
                group = format_sync_grp,
              })
              END
            '';
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
          "git@github.com:" = { insteadOf = "https://github.com/"; };
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
