# nixconf リポジトリ構造リファクタリング Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** home.nix を機能単位の home/ モジュール群に分割し、flake.nix の重複を lib/ ヘルパーに集約し、Darwin ホストを machines/ に統一する。ビルド結果 (drvPath) は一切変えない。

**Architecture:** 各タスクは「ブロックを新ファイルへ移動 → 4構成の drvPath がベースラインと一致することを確認 → コミット」のサイクルで進む。移行中は home.nix が `imports = [ ./home ];` で新ディレクトリを取り込み、段階的に縮小していく。最後に flake が ./home を直接参照して home.nix を削除する。

**Tech Stack:** Nix flakes, home-manager, nix-darwin。検証は `nix eval "path:$PWD#..."` による純粋評価のみ(ビルド不要、aarch64-darwin 上で Linux 構成も評価可能)。

**Spec:** `docs/superpowers/specs/2026-09-01-nixconf-restructure-design.md`

## Global Constraints

- 設定値・コメント(日本語コメント含む)は**移動のみ**。値の変更・追加・削除は一切禁止
- 各タスクの末尾で `./scripts/verify-drv.sh` の出力が `docs/superpowers/plans/2026-09-01-drv-baseline.txt` と完全一致すること(Task 1 以降のすべてのタスクに適用)
- flake 属性名は不変: `nixosConfigurations."schwertleite"`, `darwinConfigurations."alice"`, `darwinConfigurations."ShotanoMacBook-Pro"`, `homeConfigurations."haneta"`
- 新規 .nix ファイルはコミット前に `nix run nixpkgs#nixfmt -- <file>` で整形(整形は drvPath に影響しない)
- 検証コマンドが `error:` で失敗した場合は原因を修正してから再実行。drvPath が不一致の場合はコミットせず差分の原因を特定する

**重要な背景知識(検証方法の理由):** darwin/common.nix の `system.configurationRevision = self.rev or self.dirtyRev or null` は git のコミットハッシュを derivation に埋め込むため、素の `nix eval .#...` ではコミットするたびに drvPath が変わってしまう。`path:$PWD` フレークとして評価すると git 情報が見えず `configurationRevision = null` に固定されるので、コミットをまたいだ drvPath 比較が成立する。

---

### Task 1: 検証スクリプトとベースライン記録

**Files:**
- Create: `scripts/verify-drv.sh`
- Create: `docs/superpowers/plans/2026-09-01-drv-baseline.txt` (スクリプトの出力)

**Interfaces:**
- Produces: `./scripts/verify-drv.sh` — 引数なしで実行し、4構成の drvPath を1行ずつ `<drvPath> <attr>` 形式で stdout に出力する。以降の全タスクがこれをベースラインと diff する

- [ ] **Step 1: 検証スクリプトを作成**

`scripts/verify-drv.sh` を以下の内容で作成:

```bash
#!/usr/bin/env bash
# リファクタリング前後で 4 構成の drvPath が一致することを確認するためのスクリプト。
# path: フレークとして評価することで self.rev / self.dirtyRev を null に固定し、
# コミットをまたいだ比較を可能にする (darwin の system.configurationRevision 対策)。
set -euo pipefail
cd "$(dirname "$0")/.."
attrs=(
  'nixosConfigurations."schwertleite".config.system.build.toplevel.drvPath'
  'darwinConfigurations."alice".system.drvPath'
  'darwinConfigurations."ShotanoMacBook-Pro".system.drvPath'
  'homeConfigurations."haneta".activationPackage.drvPath'
)
for attr in "${attrs[@]}"; do
  printf '%s %s\n' "$(nix eval --raw "path:$PWD#$attr")" "$attr"
done
```

実行権限を付与: `chmod +x scripts/verify-drv.sh`

- [ ] **Step 2: スクリプトを実行してベースラインを記録**

Run: `./scripts/verify-drv.sh | tee docs/superpowers/plans/2026-09-01-drv-baseline.txt`

Expected: 4行出力され、各行が `/nix/store/....drv <attr名>` 形式。エラーが出ないこと。初回は評価に数分かかる場合がある。

- [ ] **Step 3: 再実行して安定性を確認**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL` (同一ツリーの再評価で drvPath が揺れないことの確認)

- [ ] **Step 4: コミット**

```bash
git add scripts/verify-drv.sh docs/superpowers/plans/2026-09-01-drv-baseline.txt
git commit -m "add drv baseline for behavior-preserving refactor"
```

---

### Task 2: home/ の骨格を作り、小物設定を移動

**Files:**
- Create: `home/default.nix`
- Modify: `home.nix` (先頭に imports 追加、`home.stateVersion` / `home.sessionPath` / `programs.home-manager.enable` の3ブロックを削除)

**Interfaces:**
- Produces: `home/default.nix` — home-manager モジュール。以降のタスクはここの `imports` リストに新ファイルを1行ずつ追加していく

- [ ] **Step 1: home/default.nix を作成**

```nix
{ config, ... }:

{
  imports = [ ];

  home.stateVersion = "26.05";

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  programs.home-manager.enable = true;
}
```

- [ ] **Step 2: home.nix を編集**

home.nix の属性セット先頭(`home.stateVersion = "26.05";` の位置)に `imports = [ ./home ];` を追加し、以下の3ブロックを削除:
- `home.stateVersion = "26.05";`
- `home.sessionPath = [ ... ];` (3行のブロック)
- 末尾の `programs.home-manager.enable = true;`

- [ ] **Step 3: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 4: コミット**

```bash
git add home/default.nix home.nix
git commit -m "extract home/ skeleton with misc settings"
```

---

### Task 3: sops.nix と packages.nix を移動

**Files:**
- Create: `home/sops.nix`
- Create: `home/packages.nix`
- Modify: `home/default.nix` (imports に追加)
- Modify: `home.nix` (`sops = ...` と `home.packages = ...` のブロックを削除)

**注意:** sopsFile のパスは `./secrets/...` → `../secrets/...` に変わるが、同一ファイルを指すため store パスは同じ。

- [ ] **Step 1: home/sops.nix を作成**

```nix
{ config, ... }:

{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      rclone_onedrive_token = {
        sopsFile = ../secrets/rclone_onedrive_token.bin;
        format = "binary";
      };
      rclone_onedrive_drive_id = {
        sopsFile = ../secrets/rclone_onedrive_drive_id.bin;
        format = "binary";
      };
    };
  };
}
```

- [ ] **Step 2: home/packages.nix を作成**

```nix
{ lib, pkgs, ... }:

{
  home.packages =
    with pkgs;
    [
      ibm-plex
      _0xproto
      nerd-fonts.symbols-only
      zsh-completions
      nixfmt
      nixd
      age
      sops
      ripgrep
      gh
      devcontainer
      pandoc
      (hunspell.withDicts (d: with d; [ en_US-large ]))
      slack
      glibtool
      cmake
      poppler-utils
      typst
      tinymist
      typstyle
      go
      texliveFull
      texlab
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      wl-clipboard
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      container
      pympress
      discord
      zoom-us
      _1password-cli
    ];
}
```

- [ ] **Step 3: home/default.nix の imports に追加**

```nix
  imports = [
    ./sops.nix
    ./packages.nix
  ];
```

- [ ] **Step 4: home.nix から `sops = { ... };` ブロックと `home.packages = ...;` ブロックを削除**

- [ ] **Step 5: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 6: コミット**

```bash
git add home/ home.nix
git commit -m "extract home/sops.nix and home/packages.nix"
```

---

### Task 4: zsh.nix と starship.nix を移動

**Files:**
- Create: `home/zsh.nix`
- Create: `home/starship.nix`
- Modify: `home/default.nix` (imports に `./zsh.nix` `./starship.nix` を追加)
- Modify: `home.nix` (`programs.zsh` と `programs.starship` のブロックを削除)

**注意:** emg の日本語コメント(LaunchServices の解説)は一字一句そのまま維持する。

- [ ] **Step 1: home/zsh.nix を作成**

```nix
{ pkgs, config, ... }:

{
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
        if pkgs.stdenv.hostPlatform.isDarwin then
          # `open -a Emacs' は解決を LaunchServices の登録に任せてしまう。
          # 古い世代の *ラップされていない* Emacs.app が登録に残っていると
          # そちらが起動し、emacsWithPackages が設定する EMACSLOADPATH を
          # 通らないので Nix 由来のパッケージが load-path に入らない。すると
          # init.el の `:ensure' が全部未インストール扱いになり、起動のたびに
          # ELPA から `package-user-dir' へダウンロードが走る。
          # バンドルをパスで直接指定して、必ずラッパー入りのものを起動する。
          ''
            open -a "${config.programs.emacs.finalPackage}/Applications/Emacs.app" "$@"
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
}
```

- [ ] **Step 2: home/starship.nix を作成**

```nix
{ lib, ... }:

{
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
}
```

(`$charactor` は原文ママ。typo に見えるが値の変更は禁止)

- [ ] **Step 3: home/default.nix の imports に `./zsh.nix` と `./starship.nix` を追加し、home.nix から両ブロックを削除**

- [ ] **Step 4: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 5: コミット**

```bash
git add home/ home.nix
git commit -m "extract home/zsh.nix and home/starship.nix"
```

---

### Task 5: cli-tools.nix と ghostty.nix を移動

**Files:**
- Create: `home/cli-tools.nix`
- Create: `home/ghostty.nix`
- Modify: `home/default.nix` (imports に追加)
- Modify: `home.nix` (該当ブロックを削除)

- [ ] **Step 1: home/cli-tools.nix を作成**

home.nix の zoxide / eza / direnv / fzf / yazi / bat / git / difftastic / vim / vscode / poetry の各ブロックを移す:

```nix
{ ... }:

{
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
      credential."https://github.com".helper = "!op plugin run -- gh auth git-credential";
    };
    ignores = [ ".DS_Store" ];
  };
  programs.difftastic = {
    enable = true;
    git.enable = true;
  };
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  programs.vscode = {
    enable = true;
  };
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };
}
```

- [ ] **Step 2: home/ghostty.nix を作成**

```nix
{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isLinux then
        pkgs.ghostty
      else if pkgs.stdenv.hostPlatform.isDarwin then
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
}
```

- [ ] **Step 3: home/default.nix の imports に `./cli-tools.nix` と `./ghostty.nix` を追加し、home.nix から該当11ブロックを削除**

- [ ] **Step 4: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 5: コミット**

```bash
git add home/ home.nix
git commit -m "extract home/cli-tools.nix and home/ghostty.nix"
```

---

### Task 6: emacs.nix を移動

**Files:**
- Create: `home/emacs.nix`
- Modify: `home/default.nix` (imports に `./emacs.nix` を追加)
- Modify: `home.nix` (let 束縛全体、`xdg.configFile."emacs"`、`programs.emacs` を削除。let が空になるので `let ... in` ごと削除)

**注意:** 日本語コメント2箇所(extraPackages の方針コメント、lean4-mode の flake input コメントは flake.nix 側なので対象外)を維持。

- [ ] **Step 1: home/emacs.nix を作成**

```nix
{
  lib,
  pkgs,
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
}
```

- [ ] **Step 2: home/default.nix の imports に `./emacs.nix` を追加。home.nix から let 束縛 (`emacsBase` / `lean4ModeFor` / `emacsFromUsePackage`) と `xdg.configFile."emacs"` / `programs.emacs` ブロックを削除し、引数から `emacs-conf` `lean4-mode` を外す**

home.nix の引数は `{ lib, pkgs, config, isNixOS, ... }:` になる (残存ブロックが使うもののみ)。

- [ ] **Step 3: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 4: コミット**

```bash
git add home/ home.nix
git commit -m "extract home/emacs.nix"
```

---

### Task 7: Linux 専用モジュール (rclone / mpv / plasma) を移動し home.nix を空にする

**Files:**
- Create: `home/rclone.nix`
- Create: `home/mpv.nix`
- Create: `home/plasma.nix`
- Modify: `home/default.nix` (imports に追加)
- Modify: `home.nix` (残りすべてのブロックを削除し、`{ ... }: { imports = [ ./home ]; }` だけにする)

- [ ] **Step 1: home/rclone.nix を作成**

```nix
{ pkgs, config, ... }:

{
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
}
```

- [ ] **Step 2: home/mpv.nix を作成**

```nix
{ pkgs, ... }:

{
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
}
```

- [ ] **Step 3: home/plasma.nix を作成**

```nix
{
  lib,
  pkgs,
  isNixOS,
  ...
}:

{
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
```

- [ ] **Step 4: home/default.nix の imports を最終形にし、home.nix を薄いラッパーにする**

home/default.nix の imports 最終形:

```nix
  imports = [
    ./sops.nix
    ./packages.nix
    ./zsh.nix
    ./starship.nix
    ./cli-tools.nix
    ./emacs.nix
    ./ghostty.nix
    ./rclone.nix
    ./mpv.nix
    ./plasma.nix
  ];
```

home.nix 全体を以下に置き換え:

```nix
{ ... }:

{
  imports = [ ./home ];
}
```

- [ ] **Step 5: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 6: コミット**

```bash
git add home/ home.nix
git commit -m "extract linux-only home modules; home.nix is now a thin wrapper"
```

---

### Task 8: flake が ./home を直接参照し、home.nix を削除

**Files:**
- Modify: `flake.nix` (`./home.nix` への参照3箇所を `./home` に変更)
- Delete: `home.nix`

- [ ] **Step 1: flake.nix の3箇所を書き換え**

`imports = [ ./home.nix ];` (mkNixosHost 内・mkDarwinHost 内) と homeConfigurations."haneta" の modules 内 `./home.nix` を、すべて `./home` に変更。

- [ ] **Step 2: home.nix を削除**

Run: `git rm home.nix`

- [ ] **Step 3: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 4: コミット**

```bash
git add flake.nix
git commit -m "point flake at home/ directly and remove home.nix"
```

---

### Task 9: lib/default.nix を作成し flake.nix を薄くする

**Files:**
- Create: `lib/default.nix`
- Modify: `flake.nix` (outputs 全体を書き換え)

**Interfaces:**
- Produces: `import ./lib inputs` は `{ mkNixosHost, mkDarwinHost, mkHome }` を返す
  - `mkNixosHost : path -> nixosSystem` (引数は configuration ファイル/ディレクトリのパス)
  - `mkDarwinHost : path -> darwinSystem` (同上)
  - `mkHome : { username : string } -> homeManagerConfiguration` (homeDir は `/home/${username}` に固定)

- [ ] **Step 1: lib/default.nix を作成**

```nix
# flake.nix の outputs から呼ばれるホスト定義ヘルパー。
# home-manager の共通設定 (sharedModules / extraSpecialArgs) と overlays を
# ここで一度だけ定義し、NixOS / Darwin / standalone home-manager の3系統で共有する。
inputs:
let
  inherit (inputs)
    self
    nixpkgs
    nix-darwin
    home-manager
    sops-nix
    plasma-manager
    emacs-overlay
    emacs-conf
    lean4-mode
    nix-homebrew
    homebrew-core
    homebrew-cask
    ;

  overlays = [ emacs-overlay.overlays.default ];

  hmSharedModules = [
    sops-nix.homeManagerModules.sops
    plasma-manager.homeModules.plasma-manager
  ];

  mkExtraSpecialArgs = isNixOS: {
    inherit isNixOS emacs-conf lean4-mode;
  };

  nixHomebrewModules = [
    nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        enable = true;
        user = "arakaki";
        taps = {
          "homebrew/homebrew-core" = homebrew-core;
          "homebrew/homebrew-cask" = homebrew-cask;
        };
        mutableTaps = false;
        enableZshIntegration = true;
      };
    }
  ];
in
{
  mkNixosHost =
    configurationFile:
    let
      username = "arakaki";
      homeDir = "/home/${username}";
    in
    nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self; };
      system = "x86_64-linux";
      modules = [
        configurationFile
        {
          nixpkgs.overlays = overlays;
          nix.channel.enable = false;
          nix.gc = {
            automatic = true;
            dates = "weekly";
          };
          nix.optimise = {
            automatic = true;
            dates = "weekly";
          };
        }
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = mkExtraSpecialArgs true;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = hmSharedModules;
          home-manager.users.${username} = {
            imports = [ ../home ];
            home.username = username;
            home.homeDirectory = homeDir;
          };
        }
      ];
    };

  mkDarwinHost =
    configurationFile:
    let
      username = "arakaki";
      homeDir = "/Users/${username}";
    in
    nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self; };
      modules = nixHomebrewModules ++ [
        configurationFile
        {
          nixpkgs.overlays = overlays;
          nix.channel.enable = false;
          nix.gc = {
            automatic = true;
            interval = {
              Weekday = 7;
            };
          };
          nix.optimise = {
            automatic = true;
            interval = {
              Weekday = 7;
            };
          };
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.extraSpecialArgs = mkExtraSpecialArgs false;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = hmSharedModules;
          users.users.${username}.home = homeDir;
          home-manager.users.${username} = {
            imports = [ ../home ];
            home.username = username;
            home.homeDirectory = homeDir;
          };
        }
      ];
    };

  mkHome =
    { username }:
    let
      homeDir = "/home/${username}";
    in
    home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = mkExtraSpecialArgs false;
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        inherit overlays;
      };
      modules = hmSharedModules ++ [
        {
          targets.genericLinux.enable = true;
          nixpkgs = {
            config.allowUnfree = true;
          };
          home.username = username;
          home.homeDirectory = homeDir;
        }
        ../home
      ];
    };
}
```

- [ ] **Step 2: flake.nix の outputs を書き換え**

inputs ブロック(description 含む)はそのまま。outputs を以下に置き換え:

```nix
  outputs =
    inputs:
    let
      hosts = import ./lib inputs;
    in
    {
      nixosConfigurations = {
        "schwertleite" = hosts.mkNixosHost ./machines/schwertleite/configuration.nix;
      };

      darwinConfigurations = {
        "alice" = hosts.mkDarwinHost ./darwin/common.nix;
        "ShotanoMacBook-Pro" = hosts.mkDarwinHost ./darwin/common.nix;
      };

      homeConfigurations."haneta" = hosts.mkHome { username = "haneta"; };
    };
```

(machines/ への Darwin 移行は次のタスク。ここでは参照先を変えない)

- [ ] **Step 3: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 4: コミット**

```bash
git add lib/default.nix flake.nix
git commit -m "extract host builders into lib/ and slim down flake.nix"
```

---

### Task 10: Darwin ホストを machines/ に統一

**Files:**
- Create: `machines/alice/default.nix`
- Create: `machines/shotano-macbook-pro/default.nix`
- Modify: `flake.nix` (darwinConfigurations の参照先を変更)

- [ ] **Step 1: machines/alice/default.nix を作成**

```nix
{ ... }:

{
  imports = [ ../../darwin/common.nix ];
}
```

- [ ] **Step 2: machines/shotano-macbook-pro/default.nix を作成**

```nix
{ ... }:

{
  imports = [ ../../darwin/common.nix ];
}
```

- [ ] **Step 3: flake.nix の darwinConfigurations を書き換え**

```nix
      darwinConfigurations = {
        "alice" = hosts.mkDarwinHost ./machines/alice;
        "ShotanoMacBook-Pro" = hosts.mkDarwinHost ./machines/shotano-macbook-pro;
      };
```

(flake 属性名 `"ShotanoMacBook-Pro"` は変更しないこと)

- [ ] **Step 4: 検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 5: コミット**

```bash
git add machines/ flake.nix
git commit -m "move darwin hosts under machines/"
```

---

### Task 11: 最終検証とクリーンアップ

**Files:**
- Delete: `scripts/verify-drv.sh`
- Delete: `docs/superpowers/plans/2026-09-01-drv-baseline.txt`

- [ ] **Step 1: 最終検証**

Run: `diff <(./scripts/verify-drv.sh) docs/superpowers/plans/2026-09-01-drv-baseline.txt && echo IDENTICAL`

Expected: `IDENTICAL`

- [ ] **Step 2: flake check**

Run: `nix flake check --no-build 2>&1 | tail -5`

Expected: エラーなしで終了 (warning は許容)

- [ ] **Step 3: 全 .nix ファイルの整形確認**

Run: `nix run nixpkgs#nixfmt -- --check flake.nix lib/default.nix home/*.nix machines/alice/default.nix machines/shotano-macbook-pro/default.nix`

Expected: 差分なしで終了 (差分が出たら整形して Step 1 の検証をやり直してからコミットに含める)

- [ ] **Step 4: 検証ツールを削除してコミット**

```bash
git rm scripts/verify-drv.sh docs/superpowers/plans/2026-09-01-drv-baseline.txt
git commit -m "remove throwaway drv verification tooling"
```
