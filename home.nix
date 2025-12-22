{
  lib,
  config,
  pkgs,
  osConfig ? null,
  ...
}:

{
  home.stateVersion = "25.11";

  home.packages =
    with pkgs;
    [
      nixfmt
      nixd
      ripgrep
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
    autosuggestion.enable = true;

    history.size = 10000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [
      "rm *"
      "cp *"
    ];

    initContent = lib.mkOrder 1000 (
      lib.concatStrings [
        ''
          function emc {
            emacs -nw "$@"
          }
        ''

        (lib.optionalString pkgs.stdenv.isLinux ''
          function emg {
            nohup emacs "$@" >/dev/null 2>&1 &
            disown
          }
        '')
      ]
    );
    shellAliases = {
      em = if pkgs.stdenv.isDarwin then "open -a Emacs" else "emg";
    };

    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
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
    settings.user = {
      name = "Shota Arakaki";
      email = "syotaa1@gmail.com";
    };
    ignores = [ ".DS_Store" ];
  };
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    enableZshIntegration = true;

    settings = {
      font-family = "0xProto";
      font-feature = "-dlig";
      theme = "TokyoNight";
      keybind = "shift+enter=text:\\n";
      background-opacity = 0.9;
      window-decoration = "client";
    };
  };
  programs.emacs = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;
  };

  programs.home-manager.enable = true;
}
