{
  lib,
  pkgs,
  config,
  isNixOS,
  ...
}:

{
  home.stateVersion = "25.11";

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      rclone_onedrive_token = {
        sopsFile = ./secrets/rclone_onedrive_token.bin;
        format = "binary";
      };
      rclone_onedrive_drive_id = {
        sopsFile = ./secrets/rclone_onedrive_drive_id.bin;
        format = "binary";
      };
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];
  home.packages =
    with pkgs;
    [
      ibm-plex
      nerd-fonts.symbols-only
      zsh-completions
      nixfmt
      nixd
      ripgrep
      gh
      pandoc
      (hunspell.withDicts (d: with d; [ en_US-large ]))
      slack
    ]
    ++ lib.optionals stdenv.isLinux [
      wl-clipboard
      jabref
    ]
    ++ lib.optionals stdenv.isDarwin [
    ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";
    history.size = 10000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [
      "rm *"
      "cp *"
    ];
    siteFunctions = {
      emc = ''
        emacs -nw "$@"
      '';
      emg =
        if pkgs.stdenv.isDarwin then
          ''
            open -a Emacs "$@"
          ''
        else
          ''
            nohup emacs "$@" >/dev/null 2>&1 &
            disown
          '';
    };
    shellAliases = {
      em = "emg";
    };
    localVariables = {
      ZSH_AUTOSUGGEST_STRATEGY = [
        "completion"
        "history"
      ];
    };
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
      }
    ];
  };
  programs.starship = {
    enable = true;
    enableInteractive = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = lib.concatStrings [
        "$line_break"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$fill"
        "$line_break"
        "$os"
        "$shell"
        "$charactor"
        "[>](bold cyan) "
      ];
      right_format = "$cmd_duration";
      continuation_prompt = "[>>](bold cyan) ";
      fill = {
        symbol = "-";
        style = "bold green";
      };
      character = {
        success_symbol = "\\[[➜](bold green)\\]";
        error_symbol = "\\[[✗](bold red)\\]";
        vimcmd_symbol = "\\[[V](bold green)\\]";
      };
      directory = {
        format = "\\[[$path]($style)[$read_only]($read_only_style)\\] ";
      };
      cmd_duration = {
        min_time = 500;
        format = "underwent [$duration](bold yellow)";
      };
      username = {
        style_user = "green bold";
        style_root = "black bold";
        format = "[$user]($style)";
        disabled = false;
        show_always = true;
      };
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol](bold blue) @ [$hostname](bold red) ";
        trim_at = ".companyname.com";
        disabled = false;
      };
      os = {
        format = "[($type )]($style)";
        style = "bold blue";
        disabled = false;
      };
      shell = {
        zsh_indicator = "zsh";
        bash_indicator = "bash";
        powershell_indicator = "pwsh";
        style = "cyan bold";
        disabled = false;
      };
    };
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.bat = {
    enable = true;
  };
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Shota Arakaki";
        email = "syotaa1@gmail.com";
      };
      credential."https://github.com".helper = "!gh auth git-credential";
    };
    ignores = [ ".DS_Store" ];
  };
  programs.difftastic = {
    enable = true;
    git.enable = true;
  };
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.isLinux then
        pkgs.ghostty
      else if pkgs.stdenv.isDarwin then
        pkgs.ghostty-bin
      else
        throw "unsupported system ${pkgs.stdenv.hostPlatform.system}";
    enableZshIntegration = true;

    settings = {
      font-family = [
        "IBM Plex Mono"
        "IBM Plex Sans JP"
      ];
      font-feature = "-dlig";
      theme = "Kanagawa Wave";
      keybind = "shift+enter=text:\\n";
      background-opacity = 0.9;
      window-decoration = "auto";
    };
  };
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  programs.emacs = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;
    extraPackages =
      epkgs: with epkgs; [
        pdf-tools
        vterm
        (treesit-grammars.with-grammars (
          g: with g; [
            tree-sitter-c
            tree-sitter-cpp
            tree-sitter-rust
            tree-sitter-python
            tree-sitter-markdown
            tree-sitter-markdown-inline
            tree-sitter-nix
          ]
        ))
      ];
  };
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };
  programs.rclone = {
    enable = pkgs.stdenv.isLinux;
    requiresUnit = "sops-nix.service";
    remotes = {
      onedrive = {
        config = {
          type = "onedrive";
          drive_type = "personal";
        };
        secrets = {
          token = config.sops.secrets.rclone_onedrive_token.path;
          drive_id = config.sops.secrets.rclone_onedrive_drive_id.path;
        };
        mounts = {
          "" = {
            enable = true;
            mountPoint = "${config.home.homeDirectory}/OneDrive";
            options = {
              vfs-cache-mode = "full";
            };
          };
        };
      };
    };
  };
  programs.mpv = {
    enable = pkgs.stdenv.isLinux;
    config = {
      profile = "gpu-hq";
      force-window = true;
      autofit-larger = "1280x720";
      autofit-smaller = "640x360";
    };
    scripts = with pkgs.mpvScripts; [
      mpris
    ];
  };
  programs.plasma = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    workspace = {
      theme = "breeze-dark";
    };
    fonts = {
      general = {
        family = "IBM Plex Sans JP";
        pointSize = 12;
      };
    };
    input = {
      keyboard = {
        layouts = [
          {
            layout = "jp";
          }
        ];
        options = [
          "ctrl:nocaps"
        ];
      };
    };
    kwin = {
      virtualDesktops = {
        number = 4;
        rows = 2;
      };
    };
    panels = [
      {
        location = "top";
        height = 36;
        widgets = [
          {
            applicationTitleBar = {
              behavior = {
                activeTaskSource = "activeTask";
              };
              layout = {
                elements = [ "windowTitle" ];
                horizontalAlignment = "left";
                showDisabledElements = "deactivated";
                verticalAlignment = "center";
              };
              overrideForMaximized.enable = false;
              windowTitle = {
                font = {
                  bold = false;
                  fit = "fixedSize";
                  size = 12;
                };
                hideEmptyTitle = true;
                margins = {
                  bottom = 0;
                  left = 10;
                  right = 5;
                  top = 0;
                };
                source = "appName";
              };
            };
          }
          {
            appMenu = { };
          }
          {
            panelSpacer = {
              expanding = true;
            };
          }
          {
            digitalClock = {
              calendar.firstDayOfWeek = "sunday";
              date.enable = false;
              time.format = "24h";
            };
          }
          {
            panelSpacer = {
              expanding = true;
            };
          }
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.battery"
              ];
            };
          }
        ];
      }
      {
        location = "bottom";
        lengthMode = "fit";
        height = 36;
        widgets = [
          {
            kickoff = {
              sortAlphabetically = true;
              icon = "nix-snowflake-white";
            };
          }
          {
            pager = {
              general = {
                showWindowOutlines = true;
                showApplicationIconsOnWindowOutlines = false;
                showOnlyCurrentScreen = true;
                navigationWrapsAround = true;
              };
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:firefox.desktop"
                "applications:com.mitchellh.ghostty.desktop"
              ];
            };
          }
        ];
      }
    ];
    configFile = {
      kwinrc = lib.optionalAttrs isNixOS {
        Wayland."InputMethod" = {
          value = "/run/current-system/sw/share/applications/fcitx5-wayland-launcher.desktop";
          shellExpand = true;
        };
      };
    };
  };

  programs.home-manager.enable = true;
}
