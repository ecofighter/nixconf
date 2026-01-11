{
  lib,
  pkgs,
  ...
}:

{
  home.stateVersion = "25.11";

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
      (hunspell.withDicts (d: with d; [ en_US-large ]))
      slack
      claude-code
    ]
    ++ lib.optionals stdenv.isLinux [
      wl-clipboard
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
      window-decoration = "client";
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
  programs.onedrive = {
    enable = pkgs.stdenv.isLinux;
  };

  gtk = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3 = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
    };
  };
  qt = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "breeze";
  };
  programs.gnome-shell = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
    extensions = with pkgs.gnomeExtensions; [
      { package = kimpanel; }
      { package = dash2dock-lite; }
      { package = removable-drive-menu; }
      { package = adw-gtk3-colorizer; }
    ];
  };
  dconf = lib.optionalAttrs pkgs.stdenv.isLinux {
    enable = true;
    settings = {
      "org/gnome/desktop/input-sources" = {
        xkb-options = [ "ctrl:nocaps" ];
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        font-name = "IBM Plex Sans JP  11";
        document-font-name = "IBM Plex Sans JP  11";
        monospace-font-name = "IBM Plex Mono  11";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "Papirus-Dark";
        show-battery-percentage = true;
      };
      "org/gnome/shell/extensions/dash2dock-lite" = {
        icon-size = 0.085;
        separator-thickness = 1;
        edge-distance = 0.45;
      };
      "org/gnome/shell/extensions/kimpanel" = {
        font = "IBM Plex Sans JP 12";
      };
    };
  };

  programs.home-manager.enable = true;
}
