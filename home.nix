{
  lib,
  pkgs,
  config,
  isNixOS,
  emacs-conf,
  lean4-mode,
  ...
}:

let
  emacsBase = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;
  lean4ModeFor =
    epkgs:
    epkgs.melpaBuild {
      pname = "lean4-mode";
      version = "${builtins.substring 0 8 lean4-mode.lastModifiedDate}.0";
      src = lean4-mode;
      files = ''(:defaults "data")'';
      packageRequires = with epkgs; [
        compat
        dash
        magit-section
        lsp-mode
      ];
      meta.description = "Emacs major mode for Lean 4";
    };
  emacsFromUsePackage = pkgs.emacsWithPackagesFromUsePackage {
    config = "${emacs-conf}/init.el";
    defaultInitFile = false;
    alwaysEnsure = false;
    package = emacsBase;
  };
in
{
  imports = [ ./home ];
  xdg.configFile."emacs" = {
    source = emacs-conf;
    recursive = true;
  };
  programs.emacs = {
    enable = true;
    package = emacsBase;
    # パッケージ集合の情報源は init.el の `:ensure' 一本にする。
    # ここで足すのは use-package では宣言しようがないものだけ:
    #   - lean4-mode: nixpkgs に無いので個別にビルドする (init.el からは :ensure nil で参照)
    #   - tree-sitter grammar: elisp パッケージではなく、.so を treesit-extra-load-path に載せるもの
    extraPackages =
      epkgs:
      lib.filter (p: p != null) emacsFromUsePackage.explicitRequires
      ++ [
        (lean4ModeFor epkgs)
        (epkgs.treesit-grammars.with-grammars (
          g: with g; [
            tree-sitter-c
            tree-sitter-cpp
            tree-sitter-rust
            tree-sitter-go
            tree-sitter-gomod
            tree-sitter-python
            tree-sitter-markdown
            tree-sitter-markdown-inline
            tree-sitter-typst
            tree-sitter-nix
          ]
        ))
      ];
  };
  programs.rclone = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
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
      };
    };
  };
  systemd.user.services."rclone-mount@onedrive" = {
    Unit = {
      Description = "Rclone FUSE daemon for onedrive:";
      After = [
        "rclone-config.service"
        "network-online.target"
      ];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/OneDrive";
      ExecStart = "${pkgs.rclone}/bin/rclone mount --cache-dir %C --vfs-cache-mode full onedrive: %h/OneDrive";
      Restart = "on-failure";
      Environment = "PATH=/run/wrappers/bin";
      ExecStop = "fusermount -u %h/OneDrive";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  programs.mpv = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
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
  programs.plasma = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enable = true;
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      splashScreen = {
        engine = "none";
        theme = "None";
      };
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
}
