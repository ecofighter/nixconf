# Linux 向け設定整備 計画

- 作成日: 2026-10-21
- ステータス: 計画確定。2026-10-21 の実行前確認でオーナーの回答を反映済み (9 章)。主な変更: スタンドアロン構成のユーザーを haneta から arakaki に統一し、出力名を `homeConfigurations."arakaki@dynabook"` に変更 (D-3, D-10, T-4)

## 1. 目的と成功基準

- 目的
  1. NixOS ラップトップ schwertleite で macOS とほぼ同等の実用性を得る
  2. 今後 Linux マシンやユーザーを追加しやすい構造にする
  3. スタンドアロン home-manager 構成 `haneta` を整理する
- 成功基準
  - 6 章のタスク T-1〜T-9 が完了し、各タスクの完了条件を満たす
  - `nix flake check` が通る
  - Darwin 3 構成 (alice / harmony / ShotanoMacBook-Pro) の drvPath が、作業開始時のベースラインから一切変わらない
  - schwertleite 上の手動確認 (T-11) をオーナーが実施し、問題があれば追加タスクとして記録されている

## 2. スコープ

- 対象: `flake.nix`, `lib/default.nix`, `linux/` (→ `nixos/`), `machines/schwertleite/`, `home/`, `scripts/verify-drv.sh` (新規)
- 対象外
  - シークレット管理 (sops-nix) の再有効化。`home/sops.nix`, `home/rclone.nix`, `secrets/`, `.sops.yaml` は触らない
  - Darwin 側の構造変更。`darwin/common.nix` と Darwin の builder シグネチャは変えない (例外: `mkDarwinHost` に user ファイルの import を足す。D-2)
  - 過去のドキュメント `docs/superpowers/` の書き換え
  - (補足) flake の出力名は原則として変えない。例外は `homeConfigurations."haneta"` を `"arakaki@dynabook"` に変えることだけ (実行前確認で決定)
  - Linux マシンの新規追加 (手順を規約として定めるだけ)

## 3. 前提となる文脈

- 開発機は aarch64-darwin。Linux 構成はビルドせず評価のみで検証する
- `darwin/common.nix` の `system.configurationRevision = self.rev or self.dirtyRev or null` はコミットハッシュを埋め込む。そのため drvPath の比較は必ず `path:$PWD` フレークで評価する (`docs/superpowers/plans/2026-09-01-nixconf-restructure.md:21`)
- flake に `formatter` 出力はなく、`nix fmt` は失敗する。整形は `nix run nixpkgs#nixfmt -- <files>` で行う
- 現状の主なハードコード
  - `lib/default.nix:54,59`: `mkNixosHost` 内の `username = "arakaki"` と `system = "x86_64-linux"`
  - `linux/common.nix:54`: `users.users.arakaki`
- `machines/schwertleite/hardware-configuration.nix:48` が `nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"` を設定している
- `isNixOS` は `mkExtraSpecialArgs` で home-manager に渡される。値は `mkNixosHost` で true、`mkDarwinHost` と `mkHome` で false。現在の利用箇所は `home/plasma.nix:141` のみ
- git の identity は `home/cli-tools.nix:31-34` にあり、haneta を含む全ユーザーに適用されている
- `home/ssh.nix` は Darwin 限定で、1Password エージェントを使う。Linux には SSH 設定がない
- haneta は dynabook (.sops.yaml の `dynabook_haneta`) 上の非 NixOS Linux で、`mkHome` により構築される。継続利用するかは未定
- 前回 (2026-09-01) の決定: フレームワーク (flake-parts 等) は入れない。home/ は機能単位で分割し、プラットフォーム分岐は各ファイル内に置く

## 4. 決定事項

### 4.1 長期的な指針 (変更には再検討が必要)

実装中にこれらと衝突する状況が出たら、実装を止めて報告すること。

#### D-1: NixOS システム層は `nixos/base.nix` と `nixos/desktop.nix` の 2 層にする

- 決定
  - `linux/` を `nixos/` に改名し、`linux/common.nix` を下表のとおり分割する
  - ホスト固有の設定は `machines/<host>/default.nix` に置く (`configuration.nix` から改名)
  - 集約ファイル (`nixos/default.nix`) や `laptop.nix` / `users.nix` は作らない
- 層の規則
  - `base.nix`: GUI の有無を問わず、オーナーのどの NixOS マシンにも必要なもの
  - `desktop.nix`: グラフィカルセッションを前提とするもの
  - `machines/<host>/default.nix`: ハードウェア、boot、ファイルシステムと swap、カーネル、周辺機器 (fprintd)、`networking.hostName`、`system.stateVersion`
  - 新しい共有層は、2 台目のマシンが同じブロックを必要としたときに初めて作る
- 分割表 (行番号は現 HEAD の `linux/common.nix`)

  | 行 | 内容 | 移動先 |
  |---|---|---|
  | 4-7 | `nix.settings.experimental-features` | base |
  | 9-10 | `services.resolved`, `networking.networkmanager` | base |
  | 12-15 | `time.timeZone`, `i18n.defaultLocale`, `i18n.extraLocales` | base |
  | 16-22 | `i18n.inputMethod` (fcitx5) | desktop |
  | 23-38 | `fonts.*` | desktop |
  | 40-44 | `services.xserver.enable = false`, plasma-login-manager, plasma6, xkb | desktop |
  | 46 | `services.printing` | desktop |
  | 48-52 | `security.rtkit`, `services.pipewire` | desktop |
  | 54-58 | `users.users.arakaki` | base。`users.users.${username}` とし、`username` はモジュール引数から受け取る |
  | 60-63 | `nixpkgs.config.allowUnfree`, `programs.{zsh,nix-ld,git}` | base |
  | 64-67 | `programs.firefox` | desktop |
  | 69-72 | `environment.systemPackages = [ vim wget ]` | base |

- 理由
  - 現在の 73 行は「ヘッドレスでも要るもの」と「GUI のもの」の 2 群にきれいに分かれる
  - NixOS マシンは schwertleite の 1 台だけなので、それ以上の層は投機的になる
  - `linux/` という名前のままだと、汎用 Linux である haneta 向けの設定を誤ってここに置く罠になる
- 退けた案
  - 3 層以上に分ける: 2 層目以降の利用者がいない
  - `linux/common.nix` を維持する: username がハードコードされたまま残り、ヘッドレスと GUI の区別もつかない
- 見直し条件: NixOS 以外の Linux 向けシステム層が必要になったとき

#### D-2: builder API

- 決定 (シグネチャ)

  ```nix
  userModule = username: ../home/users + "/${username}.nix";

  mkNixosHost = { machine, username ? "arakaki" }: ...
  mkDarwinHost = machine: ...
  mkHome = { username, system ? "x86_64-linux" }: ...
  ```

- `mkNixosHost`
  - `machine` は `default.nix` を含むディレクトリ
  - `nixosSystem` に `system` を渡さない。hostPlatform は `hardware-configuration.nix` から取る。drvPath が不変であることは検証済み
  - `specialArgs = { inherit self username; }`
  - 先頭に `assert builtins.pathExists (userModule username) || throw "nixconf: missing home/users/${username}.nix";` を置く
  - HM ユーザーの imports は `[ ../home (userModule username) ]`
- `mkDarwinHost`
  - シグネチャは位置引数のまま。username は内部で "arakaki" に固定
  - 変更は HM の imports に `(userModule username)` を足すことだけ。git identity が `cli-tools.nix` から抜けるため必須
- `mkHome`
  - modules の末尾に `(userModule username)` を足し、同じ assert を置く
  - スタンドアロン用のアダプタブロック (`targets.genericLinux.enable`、`allowUnfree`、`username` と `homeDirectory`) は lib 内にインラインで残す
- 固定のまま (引数にしない): ホームディレクトリの導出、overlays、hmSharedModules、`mkExtraSpecialArgs`/`isNixOS`、gc と optimise、`../home` の import
- `flake.nix` の変更は 1 行だけ: `"schwertleite" = hosts.mkNixosHost { machine = ./machines/schwertleite; };`
- 理由
  - `username` は Linux のマシンやユーザーを追加するのに必要な最小限の引数
  - Darwin には別ユーザーの利用者がいない
  - モジュールが builder の specialArgs を前提にする慣習は、`darwin/common.nix` の `self` で既に成立している
- 退けた案
  - `system` を引数にする: hostPlatform と重複する
  - Darwin も属性セット引数に揃える: 利用者がいない。Darwin に別ユーザーが現れたら、同じ `{ machine, username ? "arakaki" }` パターンを適用する
  - `extraModules` 引数を設ける: 利用者がいない
- 見直し条件: Darwin に arakaki 以外のユーザーが必要になったとき

#### D-3: ユーザーごとの値は `home/users/<username>.nix` に置く

- 決定
  - すべてのユーザーにこのファイルを必須とする。無い場合は assert のメッセージで失敗する
  - git の identity、`home.stateVersion`、個人の SSH ホスト設定などはここに置く
  - 共有の `home/<feature>.nix` にはユーザー固有の値を書かない
  - `home.stateVersion` は `home/default.nix` から各ユーザーファイルへ移す (どちらも "26.05" なので drvPath は不変)
  - (実行前確認で変更) dynabook のスタンドアロン構成はユーザー arakaki とし、macOS や NixOS と同じ `home/users/arakaki.nix` を共有する。`home/users/haneta.nix` は T-4 で削除する
  - dynabook に固有の home 設定は、現時点では無い。必要になったら `mkHome` に host 用の home モジュールを渡す引数を追加する (例: `machines/dynabook/home.nix`)。これは D-2 の変更にあたるので、追加する時点で再検討する
- 理由
  - haneta の整理の核心は、git identity が haneta に漏れていることへの対処であり、その置き場所が要る
  - 存在するときだけ import する方式 (`pathExists` で任意にする) より、必須にして assert で失敗させる方が誤りに気づける

#### D-4: home モジュールでの環境の判定

- 使う条件は次の 2 つだけ
  - `pkgs.stdenv.hostPlatform.{isLinux,isDarwin}`
  - `isNixOS` (specialArg)。意味は「NixOS のシステム層 (`/run/current-system`、`nixos/` で設定したサービスやパッケージ) に依存する」
- 拡張点 (今は追加しない): 3 つ目の環境区分が必要になった場合は `desktop` 真偽値を使う
  - `mkExtraSpecialArgs` に `desktop` を追加する
  - `mkNixosHost` は true、`mkHome` は新しい引数 `desktop ? true` を渡す
  - GUI 専用の home 機能 (`plasma.nix`、`mpv.nix`、GUI アプリ一覧) をこれで切り替える
  - 追加するのは「haneta を継続する」かつ「dynabook が Plasma 6 ではない」場合のみ
- 退けた案: `osConfig != null` で判定する (nix-darwin でも null にならない)

#### D-5: 配置規則とマシン追加手順

- Linux 専用の設定を置く場所
  1. root、システムサービス、デーモンが必要な NixOS オプション → システム層。それ以外 → home 層
  2. システム層での置き場所
     - GUI なしでも要るもの → `nixos/base.nix`
     - GUI、音声、フォント、入力メソッド → `nixos/desktop.nix`
     - そのホスト固有のもの → `machines/<host>/default.nix`
  3. home 層での置き場所
     - 該当する `home/<feature>.nix` に置く。合うものがなければ新規作成し、`home/default.nix` の imports に追加する
     - `isLinux` で囲み、NixOS 層を参照する場合だけ `isNixOS` に絞る
     - ユーザー固有の値は `home/users/<username>.nix` に置く
  4. haneta が必要とするものは必ず home 層に置く
- NixOS マシンの追加手順
  1. `machines/<host>/` を作り、生成された `hardware-configuration.nix` を置く。`nixpkgs.hostPlatform` が無ければ `default.nix` で設定する
  2. `default.nix` を書く
     - `./hardware-configuration.nix` と `../../nixos/base.nix` を import する。GUI 機には `../../nixos/desktop.nix` も加える
     - hostName、boot、`system.stateVersion`、ハードウェア設定を書く
  3. `flake.nix` に `nixosConfigurations.<host> = hosts.mkNixosHost { machine = ./machines/<host>; };` を追加する。新しいユーザーなら `username = "<u>"` を指定し、`home/users/<u>.nix` (`home.stateVersion` を含む) を作る
  4. `nix flake check` と `nix eval --raw "path:$PWD#nixosConfigurations.<host>.config.system.build.toplevel.drvPath"` で検証する

#### D-6: 検証方法

- `scripts/verify-drv.sh` で次の 5 構成の drvPath を `path:$PWD` で評価し、作業前後を比較する
  - `nixosConfigurations."schwertleite".config.system.build.toplevel.drvPath`
  - `darwinConfigurations."alice".system.drvPath`
  - `darwinConfigurations."harmony".system.drvPath`
  - `darwinConfigurations."ShotanoMacBook-Pro".system.drvPath`
  - `homeConfigurations."haneta".activationPackage.drvPath` (T-4 で `homeConfigurations."arakaki@dynabook".activationPackage.drvPath` に置き換える)
- 値の変更を意図しないタスクでは drvPath の完全一致を必須とする。値を変えるタスクでは、変わってよい構成と、具体的な `nix eval` の期待値を完了条件にする

#### D-7: スタンドアロン構成 (dynabook) の維持方針

- 実行前確認の結果: 構成は継続する。ただし保証するのは評価が通る範囲だけ。以下の「haneta」は、T-4 以降は `homeConfigurations."arakaki@dynabook"` を指す
- 方針の要約 (P0〜P3) は、計画書の削除後も残るよう `lib/default.nix` の `mkHome` の直前にコメントとして書く (T-4)


- P0 (常に緑を保つ): `nix flake check` が通り、haneta の `activationPackage.drvPath` が評価できること。x86_64-linux でのビルドや dynabook での実行時の挙動は要求しない
- P1 (既定で haneta にも入れる): `isLinux` で囲んだ home 層の項目は、次の 2 つを満たせば haneta にも入れる。クロージャの大きさや GUI アプリであることは、除外する理由にしない
  - Nix のクロージャだけで動作が完結する
  - `mkHome` で評価できる
- P2 (`isNixOS` に絞る): 次のどちらかに当たる項目
  - 動作に `nixos/` や `/run/current-system` が提供するもの (システムパッケージ、サービス、ソケット、setuid ラッパー、システム層の 1Password GUI が提供するエージェント) を必要とする
  - `mkHome` で評価できない
- P3 (未定の間に haneta 用の補完を入れる条件): 次の 3 つをすべて満たすときだけ
  1. その home-manager オプションのデフォルト値が `nixosConfig`/`osConfig` に依存している
  2. schwertleite の HM と haneta で `nix eval` した値が異なり、どちらも明示的に設定していない
  3. 補完は同じオプションを `lib.mkIf (isLinux && !isNixOS)` で設定する

  HM 全体を調べた結果、現時点で該当するのは `fonts.fontconfig.enable` だけ
- P4 (「継続」の回答後に行う): nixos-icons、`nix.gc`、`desktop` フラグ、NVIDIA 設定、オーナーから報告された実行時の問題への対処。いずれも arakaki の 4 構成の drvPath を変えてはならない

### 4.2 短中期の設計

合理的な理由があれば実装中に調整してよい。調整した場合はコミットメッセージに記録すること。

#### D-10: haneta の git identity (実行前確認で廃止)

- **オーナーの回答 (U-1): haneta を arakaki に変更し、macOS と統一する。** dynabook の構成は `home/users/arakaki.nix` を使い、git identity は T-3 で移した値を共有する。そのため、以下の `useConfigOnly` の設計は実施しない (参考として残す)
- (旧設計) `home/users/haneta.nix` に `programs.git.settings.user.useConfigOnly = true;` を置き、name と email は設定しない
- 効果: identity が未設定の間、`git commit` は "Please tell me who you are" で失敗する。推測された identity でコミットされることはない。name と email を設定した後も `useConfigOnly` は無害なので残してよい
- オーナーの回答 (U-1) ごとの変更

  | 回答 | 変更 |
  |---|---|
  | haneta は本人 | `programs.git.settings.user = { name = "Shota Arakaki"; email = "syotaa1@gmail.com"; };` を追加 |
  | 別人 | その人が提示した name と email を追加 |
  | 未回答 | 変更しない |

- 退けた案
  - arakaki の identity をデフォルトにする: haneta の正体を仮定してしまい、漏れも再発する
  - 未設定のまま自動検出に任せる: 誤った identity で黙ってコミットされうる

#### D-11: haneta 用の fontconfig 補完

- `home/packages.nix` の引数を `{ lib, pkgs, isNixOS, ... }` にし、`fonts.fontconfig.enable = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && !isNixOS) true;` を追加する
- 必ず `mkIf` の形で書くこと。真偽式をそのまま代入すると schwertleite で false になり、drvPath が変わる (検証済み)
- これは D-7 の P3 に該当する唯一の項目

#### D-12: 1Password と SSH

- `nixos/desktop.nix`
  - ヘッダを `{ pkgs, username, ... }:` にする。リテラルの "arakaki" は使わない
  - 次を追加する

    ```nix
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ username ];
      };
    ```

- `home/ssh.nix` を次で全面置換する

  ```nix
  {
    lib,
    pkgs,
    isNixOS,
    ...
  }:

  let
    inherit (pkgs.stdenv.hostPlatform) isDarwin;
  in
  {
    # Linux の agent は NixOS の programs._1password-gui が提供するため isNixOS に限定する
    programs.ssh = lib.mkIf (isDarwin || isNixOS) {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        IdentityAgent =
          if isDarwin then
            "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
          else
            "~/.1password/agent.sock";
      };
    };
  }
  ```

- 理由
  - setgid の `op` ラッパー、`1Password-BrowserSupport`、polkit のポリシー所有者は、NixOS モジュールでしか作れない
  - エージェントのソケットはシステム層が提供するので、D-7 の P2 により `isNixOS` に絞る
  - ソケットが無いときの ssh は、エラーを記録して鍵ファイルに進むだけで、止まらない (macOS で確認済み)
- 1Password の自動起動: NixOS モジュールにそのためのオプションはない。アプリ自身の "Start at login" 設定を使う (T-11)
- haneta は `op` を受け取らない。必要になったら P4 として `home/packages.nix` に `lib.optionals (stdenv.hostPlatform.isLinux && !isNixOS) [ _1password-cli ]` を追加する

#### D-13: Zoom と OBS (`nixos/desktop.nix`)

```nix
  programs.zoom-us.enable = true;
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true; # 拒否する場合はこの行を削除 (OBS は残り、v4l2loopback は入らない)
  };
```

- Zoom をシステム層に置く理由: home 層では pipewire-pulse と xdg-desktop-portal の統合が失われ、Wayland での画面共有が壊れる
- 仮想カメラは zen カーネル向けの外部カーネルモジュール `v4l2loopback` を使う
  - カーネル更新でビルドが壊れるリスクがある。ただし `meta.broken` は macOS 上の評価でも検出でき、ビルドが失敗しても実行中の世代は残る
  - 壊れたら上記の 1 行を削除する

#### D-14: GUI アプリ (home 層、haneta にも入る)

`home/packages.nix` に `let` で真偽値を 1 つ定義し、既存の `isLinux` リストと Darwin リストの間に専用のリストを挟む。

```nix
let
  # desktop フラグ (D-4) を導入する場合はこの式だけを差し替える
  withLinuxDesktopApps = pkgs.stdenv.hostPlatform.isLinux;
in
...
      ++ lib.optionals withLinuxDesktopApps [
        discord
        libreoffice-qt
        pympress
      ]
```

- 置き場所: Darwin のリストは変えない (Darwin の drvPath を不変に保つため)
- 実行前確認 (U-4) の結果: teams-for-linux と JabRef は拒否されたので入れない。LibreOffice と pympress は入れる
- スタンドアロン構成にも入れる根拠は D-7 の P1。いずれも `mkHome` で評価できることを確認済み
- 将来 `desktop` フラグを導入するときは、`withLinuxDesktopApps = pkgs.stdenv.hostPlatform.isLinux && desktop;` に差し替える

#### D-15: コンテナ実行環境は podman (`nixos/base.nix`、`programs.git.enable` の後)

```nix
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
```

- macOS の `container` に相当するものとして入れる。rootless でデーモンが不要
- `docker` 互換コマンドを提供するので、共有している `devcontainer` CLI から使える (推測。T-11 で確認)
- Docker Desktop は既に外している (commit `03875ce`)
- 代替: devcontainer が動かない場合は docker に切り替えるか、`--docker-path podman` を使う (U-5)

#### D-16: fcitx5 のデフォルトプロファイル (`nixos/desktop.nix`、拒否可)

`i18n.inputMethod` ブロックの `fcitx5.addons` の後に次を追加する。

```nix
    fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "jp";
        DefaultIM = "skk";
      };
      "Groups/0/Items/0".Name = "keyboard-jp";
      "Groups/0/Items/1".Name = "skk";
    };
```

- SKK と L 辞書は既に有効になっている。この設定は、新しいプロファイルでも SKK が最初から並ぶようにするだけ
- 既存の `~/.config/fcitx5/profile` がある場合はそちらが優先される

#### D-17: OneDrive (実行前確認 U-3 で「不要」と回答。実施しない。参考として残す)

- 設定: `nixos/desktop.nix` に `services.onedrive.enable = true;` を追加する
- 手順: 有効化する前に schwertleite 上で `nix shell nixpkgs#onedrive -c onedrive` を 1 回実行し、ブラウザで認可を済ませる
- 理由: `onedrive-launcher` は `default.target` に紐づいている。認可前に有効化すると、ログインのたびに失敗を繰り返す
- 退けた案: `rclone.nix` を復活させる。HM が管理する `rclone.conf` と、rclone によるトークンの書き換えが衝突する

#### D-18: 対応しない項目

| 項目 | 理由 |
|---|---|
| karabiner-elements | 設定がリポジトリに無い。既知の変更 (ctrl:nocaps) は対応済み |
| microsoft-outlook | Linux 版クライアントが無い。Web 版を使う |
| claude (デスクトップアプリ) | nixpkgs に無い |
| `anthropics/tap/ant` | nixpkgs に無い (nixpkgs の `ant` は Apache Ant)。パッケージ化すると `pkgs/` という新しい構造が要る |
| ctrl:nocaps 以外のキー変更 | 要件が無い。必要になったら `services.keyd` を使う |

## 5. 実装時の制約・規約

- 値の移動は一字一句そのまま行う。タスクに書かれていない値は変えない (D-1、D-6)
- 各タスクを 1 コミットにする。コミット前に `scripts/verify-drv.sh` と `nix flake check` を実行し、結果を完了条件と照合する (D-6)
- drvPath の比較は必ず `path:$PWD` で評価する。素の `.#` は使わない (D-6)
- 新規または変更した .nix ファイルは `nix run nixpkgs#nixfmt -- <files>` で整形する (`nix fmt` は使えない)
- `nixos/` 配下に "arakaki" のリテラルを書かない (D-2、D-12)
- 共有の `home/<feature>.nix` にユーザー固有の値を書かない (D-3)
- home 層の Linux 項目を haneta に入れるかは D-7 の P1〜P3 で判定する
- `darwin/common.nix` と `docs/superpowers/` は変更しない
- haneta の drvPath が変わるタスクでは、変更前と変更後の値をコミットメッセージに記録する

## 6. 実装タスク

| ID | タスク | 根拠 | 依存 | 並列可 |
|---|---|---|---|---|
| T-1 | 検証スクリプト作成とベースライン記録 | D-6 | - | × |
| T-2 | 構造の再編 (drvPath 不変) | D-1, D-2, D-3, D-5 | T-1 | × |
| T-3 | git identity を arakaki.nix へ移動 | D-3 | T-2 | × |
| T-4 | スタンドアロン構成を arakaki に統一し整理する | D-3, D-7, D-10, D-11 | T-3 | × (T-7 と同じファイル) |
| T-5 | 1Password、CLI、SSH | D-12 | T-3 | × (desktop.nix を共有) |
| T-6 | Zoom、OBS | D-13 | T-5 | × |
| T-7 | GUI アプリ一覧 | D-14, D-7 | T-4 | × |
| T-8 | podman | D-15 | T-3 | × |
| T-9 | fcitx5 のデフォルトプロファイル (拒否可) | D-16 | T-6 | × |
| ~~T-10~~ | OneDrive。U-3 で「不要」と回答されたため実施しない | D-17 | - | - |
| T-11 | schwertleite と dynabook での手動確認 (オーナーが実施) | D-12〜D-16, D-7 | T-9 | - |

すべてのタスクは同じリポジトリで行う。コミット順を一意にするため、並列には実行しない。

共通の変数: `F="path:$PWD"`。

### T-1: 検証スクリプト作成とベースライン記録

- 目的: 以降のすべてのタスクで使う比較基準を作る
- 変更対象: `scripts/verify-drv.sh` (新規)
- 内容: 次の内容で作成し、`chmod +x` する

  ```bash
  #!/usr/bin/env bash
  # 5 構成の drvPath を出力する。path: フレークで評価して self.rev / self.dirtyRev を null に固定し、
  # コミットをまたいだ比較を可能にする (darwin の system.configurationRevision 対策)。
  set -euo pipefail
  cd "$(dirname "$0")/.."
  attrs=(
    'nixosConfigurations."schwertleite".config.system.build.toplevel.drvPath'
    'darwinConfigurations."alice".system.drvPath'
    'darwinConfigurations."harmony".system.drvPath'
    'darwinConfigurations."ShotanoMacBook-Pro".system.drvPath'
    'homeConfigurations."haneta".activationPackage.drvPath'
  )
  for attr in "${attrs[@]}"; do
    printf '%s %s\n' "$(nix eval --raw "path:$PWD#$attr")" "$attr"
  done
  ```

  実行結果をリポジトリ外 (例: `/tmp/drv-base.txt`) に保存し、以降の比較に使う。ベースラインはコミットしない
- 完了条件
  - 5 行が出力される
  - 2 回実行して出力が一致する
- コミット: スクリプトのみ

### T-2: 構造の再編 (drvPath 不変)

- 目的: D-1〜D-3 の構造を、値を一切変えずに導入する
- 変更対象: `lib/default.nix`, `flake.nix`, `linux/common.nix` → `nixos/base.nix` と `nixos/desktop.nix`, `machines/schwertleite/configuration.nix` → `default.nix`, `home/default.nix`, `home/users/arakaki.nix` と `home/users/haneta.nix` (新規)
- 内容
  - `lib/default.nix` を D-2 のとおり変更する: `userModule`、`mkNixosHost` の引数と assert と specialArgs、`system` 行の削除、3 builder への `(userModule username)` の追加、`mkHome` の assert
  - `nixos/base.nix`: ヘッダは `{ pkgs, username, ... }:`。D-1 の表で base に分類された行を移す
  - `nixos/desktop.nix`: ヘッダは `{ pkgs, ... }:`。desktop に分類された行を移す
  - `linux/` を削除する
  - `git mv machines/schwertleite/configuration.nix machines/schwertleite/default.nix` を実行し、imports を `../../nixos/base.nix` と `../../nixos/desktop.nix` にする
  - `flake.nix`: schwertleite の行を `hosts.mkNixosHost { machine = ./machines/schwertleite; }` にする
  - `home/default.nix` から `home.stateVersion` を削除し、`home/users/arakaki.nix` と `home/users/haneta.nix` をそれぞれ `{ home.stateVersion = "26.05"; }` として作成する
- 完了条件
  - `diff <(scripts/verify-drv.sh) /tmp/drv-base.txt` が差分なしで終わる (5 構成とも一致)
  - `nix flake check` が通る
  - `linux/` と `machines/schwertleite/configuration.nix` が存在しない
  - `grep -rn arakaki nixos/` が何も出力しない
  - `lib/default.nix` の username を一時的に `"nobody"` にすると `nixconf: missing home/users/nobody.nix` で失敗する (確認後は元に戻す)
- 注意点: `system` を削除しても drvPath は変わらない (検証済み)。変わった場合は原因を特定するまでコミットしない

### T-3: git identity を arakaki.nix へ移動

- 目的: haneta への identity の漏れを止める (D-3)
- 変更対象: `home/cli-tools.nix`, `home/users/arakaki.nix`
- 内容: `home/cli-tools.nix:31-34` の `user = { name = "Shota Arakaki"; email = "syotaa1@gmail.com"; };` を削除し、`home/users/arakaki.nix` に `programs.git.settings.user = { ... };` として追加する
- 完了条件
  - verify-drv の結果、schwertleite と Darwin 3 構成は T-2 後の値と一致し、haneta だけが変わる
  - `nix eval --raw "$F#nixosConfigurations.schwertleite.config.home-manager.users.arakaki.programs.git.settings.user.name"` → `Shota Arakaki`
  - `darwinConfigurations.alice.config.home-manager.users.arakaki...` で同じ評価 → `Shota Arakaki`
  - `nix flake check` が通る
- 注意点: この時点で haneta には git identity が無い。T-4 でユーザーを arakaki に統一すると、`home/users/arakaki.nix` から identity が入る (D-10 の改訂)

### T-4: スタンドアロン構成を arakaki に統一し整理する

- 目的: U-1 の回答 (haneta を arakaki に変更し macOS と統一) を反映する。D-11 を入れ、D-7 の方針をコードに残す
- 変更対象: `flake.nix`, `home/users/haneta.nix` (削除), `home/packages.nix`, `lib/default.nix` (コメント), `scripts/verify-drv.sh`
- 内容
  - `flake.nix`: `homeConfigurations."haneta" = hosts.mkHome { username = "haneta"; };` を `homeConfigurations."arakaki@dynabook" = hosts.mkHome { username = "arakaki"; };` に置き換える
  - `home/users/haneta.nix` を削除する (`git rm`)
  - `home/packages.nix` に D-11 の設定を入れる
  - `lib/default.nix` の `mkHome` の直前に、D-7 の P0〜P3 を数行に要約したコメントを書く。既存のコメントと同じく日本語で書き、計画書は参照しない (Phase 6 で削除されるため)。内容は次の 4 点
    - 非 NixOS 機向けで、保証するのは評価が通ることまで
    - `isLinux` の home 項目は、Nix だけで完結し `mkHome` で評価できれば入れる
    - NixOS 層に依存するもの、または評価できないものは `isNixOS` に絞る
    - 補完は、HM オプションのデフォルトが nixosConfig に依存する場合だけ `isLinux && !isNixOS` で入れる
  - `scripts/verify-drv.sh`: haneta の属性を `'homeConfigurations."arakaki@dynabook".activationPackage.drvPath'` に置き換える
- 完了条件
  - `nix eval --raw "$F#homeConfigurations.\"arakaki@dynabook\".config.home.homeDirectory"` → `/home/arakaki`
  - `nix eval --raw "$F#homeConfigurations.\"arakaki@dynabook\".config.programs.git.settings.user.name"` → `Shota Arakaki`
  - `nix eval "$F#homeConfigurations.\"arakaki@dynabook\".config.fonts.fontconfig.enable"` → `true`
  - `nix eval "$F#nixosConfigurations.schwertleite.config.home-manager.users.arakaki.fonts.fontconfig.enable"` → `true`
  - `nix eval "$F#darwinConfigurations.alice.config.home-manager.users.arakaki.fonts.fontconfig.enable"` → `false`
  - verify-drv の結果、先頭 4 行 (schwertleite と Darwin 3 構成) が T-3 後の値と一致する
  - `git grep -n haneta -- ':!docs'` の結果が `.sops.yaml` の `dynabook_haneta` 行だけになる (シークレットは対象外なので残す)
  - `nix flake check` が通る
- 注意点: dynabook 側のアカウントを arakaki にする作業は手動 (T-11)

### T-5: 1Password、CLI、SSH

- 目的: D-12 を入れる
- 変更対象: `nixos/desktop.nix`, `home/ssh.nix`
- 完了条件
  - `nix eval --json "$F#nixosConfigurations.schwertleite.config.home-manager.users.arakaki.home.file" --apply 'f: f.".ssh/config".text'` → `"Host *\n  IdentityAgent ~/.1password/agent.sock\n"`
  - 同じ式を `darwinConfigurations.alice.config.home-manager.users.arakaki.home.file` に対して実行 → `"Host *\n  IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"\n"`
  - `nix eval --json "$F#homeConfigurations.\"arakaki@dynabook\".config.home.file" --apply 'f: f ? ".ssh/config"'` → `false`
  - `nix eval --json "$F#nixosConfigurations.schwertleite.config" --apply 'c: { owners = c.programs._1password-gui.polkitPolicyOwners; wrappers = builtins.all (n: c.security.wrappers ? ${n}) ["op" "1Password-BrowserSupport"]; opGroup = c.security.wrappers.op.group; }'` → `{"opGroup":"onepassword-cli","owners":["arakaki"],"wrappers":true}`
  - `grep -rn arakaki nixos/` が何も出力しない
  - verify-drv の結果、Darwin 3 構成と haneta は不変で、schwertleite だけが変わる
  - `nix flake check` が通る

### T-6: Zoom、OBS

- 目的: D-13 を入れる
- 変更対象: `nixos/desktop.nix`
- 完了条件
  - `nix eval --json "$F#nixosConfigurations.schwertleite.config" --apply 'c: { zoom = c.programs.zoom-us.enable; obs = builtins.elem c.programs.obs-studio.finalPackage c.environment.systemPackages; v4lLoaded = builtins.elem "v4l2loopback" c.boot.kernelModules; v4lPkg = builtins.elem c.boot.kernelPackages.v4l2loopback c.boot.extraModulePackages; v4lBroken = c.boot.kernelPackages.v4l2loopback.meta.broken; }'` → `{"obs":true,"v4lBroken":false,"v4lLoaded":true,"v4lPkg":true,"zoom":true}`
  - 仮想カメラを拒否した場合は `v4lLoaded` と `v4lPkg` が `false` になる
  - Darwin 3 構成と haneta は不変
  - `nix flake check` が通る

### T-7: GUI アプリ一覧

- 目的: D-14 を入れる
- 変更対象: `home/packages.nix`
- 完了条件
  - `nix eval --json "$F#nixosConfigurations.schwertleite" --apply 's: let hp = s.config.home-manager.users.arakaki.home.packages; in builtins.all (p: builtins.elem p hp) (with s.pkgs; [ discord libreoffice-qt pympress ])'` → `true`
  - `nix eval --json "$F#homeConfigurations.\"arakaki@dynabook\"" --apply 's: let hp = s.config.home.packages; in builtins.all (p: builtins.elem p hp) (with s.pkgs; [ discord libreoffice-qt pympress ])'` → `true`
  - schwertleite のトップレベルを評価したとき、`warning` 行が出ない
  - Darwin 3 構成は不変。schwertleite と haneta は変わる
  - `nix flake check` が通る
- 注意点: 拒否された項目は、モジュールと上記の確認式の両方から削除する

### T-8: podman

- 目的: D-15 を入れる
- 変更対象: `nixos/base.nix`
- 完了条件
  - `nix eval --json "$F#nixosConfigurations.schwertleite.config" --apply 'c: { compat = c.virtualisation.podman.dockerCompat; dns = c.virtualisation.podman.defaultNetwork.settings.dns_enabled; podman = builtins.elem c.virtualisation.podman.package c.environment.systemPackages; dockerShim = builtins.any (p: builtins.match "podman-docker-compat.*" (p.name or "") != null) c.environment.systemPackages; subuid = c.users.users.arakaki.autoSubUidGidRange; }'` → 5 つのキーがすべて `true`
  - Darwin 3 構成と haneta は不変
  - `nix flake check` が通る

### T-9: fcitx5 のデフォルトプロファイル (拒否可)

- 目的: D-16 を入れる
- 変更対象: `nixos/desktop.nix`
- 完了条件
  - `nix eval --json "$F#nixosConfigurations.schwertleite.config.environment.etc" --apply 'e: e."xdg/fcitx5/profile".text'` → `"[GroupOrder]\n0=Default\n\n[Groups/0]\nDefault Layout=jp\nDefaultIM=skk\nName=Default\n\n[Groups/0/Items/0]\nName=keyboard-jp\n\n[Groups/0/Items/1]\nName=skk\n"`
  - Darwin 3 構成と haneta は不変
  - `nix flake check` が通る

### T-10: OneDrive (U-3 で「必要」と回答があった場合のみ)

- 目的: D-17 を入れる
- 変更対象: `nixos/desktop.nix`
- 完了条件
  - `nix eval --json "$F#nixosConfigurations.schwertleite.config" --apply 'c: { tmpl = c.systemd.user.services ? "onedrive@"; launcher = c.systemd.user.services.onedrive-launcher.wantedBy; }'` → `{"launcher":["default.target"],"tmpl":true}`
  - コミットメッセージに、switch 前の手動認可手順 (D-17) を記載する

### T-11: 手動確認 (オーナーが実施。評価では確かめられない項目)

schwertleite で `nixos-rebuild switch` した後に次を確認する。

- M1 (1Password と SSH)
  1. 1Password にサインインする
  2. Settings > Developer > "Use the SSH agent" と Settings > General > "Start at login" を有効にする
  3. `SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l` で鍵が一覧に出ることを確認する
  4. `ssh -T git@github.com` で認証が通ることを確認する
- M2 (ブラウザ連携): Firefox の 1Password 拡張がデスクトップアプリに接続できる。できない場合は `nixos/desktop.nix` に `environment.etc."1password/custom_allowed_browsers".text = "firefox\n";` を追加する
- M3 (CLI と指紋): `op whoami` が使える。システム認証によるロック解除で指紋が使える (推測。使えない場合はパスワードでの解除になるだけ)
- M4 (Zoom と OBS)
  - Wayland 上で Zoom の画面共有ができる
  - OBS に "Virtual Camera" があり、`v4l2-ctl --list-devices` にループバックデバイスが出る
- M5 (podman と devcontainer)
  - `podman run --rm docker.io/library/alpine true` が成功する
  - サンプルリポジトリで `devcontainer up --workspace-folder <dir>` が動く
- M6 (日本語入力)
  - 新しいログインで、fcitx5 のグループに SKK がある
  - macskk で使っていた個人設定 (ユーザー辞書など) で、移行が必要なものが無いことをオーナーが確認する

dynabook では次を行う。

- アカウントを arakaki にする。新規作成するか、haneta から移行する。ホームディレクトリは `/home/arakaki`
- `home-manager switch --flake .#arakaki@dynabook` を実行する
- 有効化時に `non-nixos-gpu-setup` の sudo コマンドが表示されたら実行する
- `chsh` でディストリビューションの zsh に切り替える
- ghostty と emacs で日本語を入力できることを確認する

失敗した項目は D-7 の P4 として、新しいタスクに起こす。

## 7. 実行順序

```
T-1 → T-2 → T-3 → T-4 → T-5 → T-6 → T-7 → T-8 → T-9 → (T-10) → T-11
```

- 依存関係として本質的なのは次の 3 つだけ
  - T-2 は T-3 以降すべての前提
  - T-5 は `username` の specialArg (T-2) を必要とする
  - T-4 と T-7 は同じ `home/packages.nix` を編集する
- 上記の順序は、コミットを一意にするための直列化
- 拒否された項目は、その行またはそのタスクを飛ばすだけでよい。他のタスクには影響しない

## 8. 検証計画

- 各タスク: verify-drv による drvPath の比較 (どの構成が変わってよいかはタスクごとに指定)、`nix eval` の期待値、`nix flake check`
- Darwin 3 構成: T-1 から最後まで drvPath が不変であること (全体の不変条件)
- 実機: T-11 の手動確認

## 9. リスクと未解決事項

| ID | 内容 | 影響 | 解決の方法・タイミング | 未解決時のデフォルト |
|---|---|---|---|---|
| U-1 | haneta は誰か、git identity をどうするか | T-4 | **解決 (2026-10-21)**: haneta を arakaki に変更し macOS と統一する。出力名は `"arakaki@dynabook"` | - |
| U-2 | haneta を継続するか廃止するか | D-7 | **解決**: 継続する (P0 の範囲のみ) | - |
| U-3 | Linux で OneDrive が必要か | T-10 | **解決**: 不要。T-10 は実施しない | - |
| U-4 | 拒否できる項目 | T-6、T-7、T-9 | **解決**: teams-for-linux と JabRef を拒否。LibreOffice、pympress、OBS 仮想カメラ、T-9 は入れる | - |
| U-5 | コンテナ実行環境 | T-8 | **解決**: podman。M5 が失敗した場合は再検討する | - |
| U-6 | dynabook のディストリビューション、DE、GPU、ログインシェル | D-4、D-7 | 継続する場合にオーナーが確認する | Plasma 6、Mesa、`chsh` は手動 |
| R-1 | v4l2loopback がカーネル更新でビルドできなくなる | schwertleite の rebuild | 発生時に `enableVirtualCamera` の行を削除する | - |
| R-2 | Nix でビルドした GTK アプリで、haneta で日本語入力ができない (推測) | haneta | T-11 で確認し、P4 として対処する | - |

## 付録 A: スタンドアロン構成の廃止手順 (将来、廃止する場合。T-4 の実施後を前提とする)

1. `flake.nix`: `homeConfigurations."arakaki@dynabook"` の行を削除する
2. (`home/users/arakaki.nix` は他の構成でも使うので残す)
3. `lib/default.nix`: `mkHome` を削除する。`nixpkgs` と `home-manager` の inputs は他の builder でも使うので残す (`flake.lock` は変わらない)
4. `home/packages.nix`: `fonts.fontconfig.enable` の行を削除し、引数から `isNixOS` を外す。`grep -rn '!isNixOS' home/` で、ほかの P3/P4 補完が残っていないか確認する。`mkExtraSpecialArgs` の `isNixOS` と `plasma.nix` での利用は残す
5. `scripts/verify-drv.sh` から haneta の属性を削除する
6. `.sops.yaml` の `dynabook_haneta` は、シークレットを復活させるまで残す
7. (任意) dynabook で `home-manager uninstall` を実行する
8. 確認
   - `nix flake check` が通る
   - 残る 4 構成の drvPath が、廃止前と一致する
   - `grep -rn 'haneta\|mkHome\|genericLinux\|dynabook' --exclude-dir=docs --exclude-dir=.git .` の結果が `.sops.yaml` の行だけになる

## 付録 B: レビューで変更された主な点

- drvPath の比較は `path:$PWD` で行う。素の `.#` で比較すると、Darwin の drvPath がコミットごとに変わるため誤検知になる
- `system` 引数の削除と、user ファイルの必須化は、作業用コピーで drvPath が不変であることを確認してから採用した
- `linux/` は `nixos/` に改名した。汎用 Linux 向けの設定を誤って置かないようにするため
- `home.stateVersion` はユーザーごとのファイルに移した。per-user の規則と一致させるため
- Darwin の builder シグネチャは変えなかった。利用者がいないため
- haneta の git identity は、未設定のまま放置せず `useConfigOnly` で止める案だった。実行前確認で、ユーザーを arakaki に統一する方針に置き換わった (D-10)
- haneta に GUI アプリを入れるかどうかは、場当たり的に決めず、評価で確かめられる規則 P1〜P3 で判定する
- 1Password、Zoom、OBS はシステム層に置いた。home 層ではシステムとの統合が失われるため
- 評価では確かめられない項目は T-11 の手動確認にまとめた
