# nixconf リポジトリ構造リファクタリング設計

日付: 2026-09-01

## 目的

以下の3つの痛みを解消する。振る舞い(ビルド結果の derivation)は一切変えない純粋な構造整理とする。

1. **home.nix の肥大化** — 全 home-manager 設定が1ファイル(~510行)に集約されている
2. **flake.nix の重複** — `mkNixosHost` / `mkDarwinHost` / `homeConfigurations."haneta"` の3箇所で home-manager の設定(sharedModules、extraSpecialArgs、useGlobalPkgs 等)や overlays が繰り返し書かれている
3. **全体の見通し** — ホスト定義の置き場所が NixOS(machines/)と Darwin(darwin/common.nix 直接参照)で非対称

## 方針

- フレームワーク(flake-parts 等)は導入せず、素の Nix で整理する
- home.nix は**機能単位**で分割し、プラットフォーム分岐(`isLinux` / `isDarwin` / `isNixOS`)は各ファイル内に内包する
- 設定値・コメントは移動のみで変更しない

## 最終的なディレクトリ構造

```
flake.nix                  inputs 定義と outputs の宣言だけの薄いファイル
lib/
└─ default.nix             mkNixosHost / mkDarwinHost / mkHome ヘルパー
home/
├─ default.nix             imports 一覧 + stateVersion + sessionPath 等の小物
├─ packages.nix            home.packages(プラットフォーム分岐内包)
├─ sops.nix
├─ zsh.nix                 zsh + siteFunctions(emg の darwin 分岐もここ)
├─ starship.nix
├─ cli-tools.nix           zoxide / eza / direnv / fzf / yazi / bat / vim /
│                          git / difftastic / vscode / poetry
├─ emacs.nix               emacsBase / lean4-mode / use-package 連携 +
│                          xdg.configFile."emacs"
├─ ghostty.nix
├─ rclone.nix              rclone + systemd mount unit(Linux のみ有効)
├─ mpv.nix                 Linux のみ有効
└─ plasma.nix              Linux のみ有効
darwin/common.nix          現状維持
linux/common.nix           現状維持
machines/
├─ schwertleite/           現状維持
├─ alice/default.nix       ../../darwin/common.nix を import する薄いファイル
└─ shotano-macbook-pro/default.nix  同上
secrets/                   現状維持
```

flake の属性名(`nixosConfigurations."schwertleite"`、`darwinConfigurations."alice"`、
`darwinConfigurations."ShotanoMacBook-Pro"`、`homeConfigurations."haneta"`)は不変。

## lib/default.nix の設計

- `inputs`(flake の inputs 一式)を受け取り `{ mkNixosHost, mkDarwinHost, mkHome }` を返す関数
- **home-manager 共通チャンク**を内部関数として1回だけ定義し、3種のビルダーすべてが使う:
  - `sharedModules`: sops-nix の homeManagerModules.sops、plasma-manager の homeModules.plasma-manager
  - `extraSpecialArgs`: `isNixOS`(ビルダーごとに真偽が異なる)、`emacs-conf`、`lean4-mode`
  - `useGlobalPkgs = true`、`useUserPackages = true`
- overlays(emacs-overlay)も lib 内で1回だけ定義
- nix-homebrew モジュール群(taps 固定・mutableTaps = false 等)は `mkDarwinHost` 内に移動
- nix.gc / nix.optimise は Linux が `dates`、Darwin が `interval` とスキーマが異なるため
  各ビルダー内に残す。値は現状のまま
- `specialArgs = { inherit self; }` も現状どおり各ビルダーで渡す

flake.nix 本体は inputs 宣言と、lib を呼んでホストを列挙する短い outputs になる。

## home/ 分割の方針

- 各ファイルは現在の home.nix の該当ブロックをそのまま移すだけで、値は変更しない
- `let` 束縛(emacsBase、lean4ModeFor、emacsFromUsePackage)は emacs.nix に移す
- `isLinux` / `isDarwin` 分岐、`isNixOS`(plasma の kwinrc)も各ファイル内にそのまま保持
- home/default.nix が全ファイルを import し、flake 側からは従来どおり1モジュールとして参照
- 既存の日本語コメント(emg の LaunchServices 解説、emacs extraPackages の方針コメント等)は
  そのまま維持する

## 検証方法(振る舞い不変の保証)

リファクタ前に main で以下の derivation パスを記録し、リファクタ後に完全一致を確認する:

- `nixosConfigurations.schwertleite.config.system.build.toplevel.drvPath`
- `darwinConfigurations."alice".system.drvPath`
- `darwinConfigurations."ShotanoMacBook-Pro".system.drvPath`
- `homeConfigurations."haneta".activationPackage.drvPath`

すべて評価のみ(ビルド不要)のため、aarch64-darwin 上で Linux 構成も検証できる。
4つとも一致すれば生成されるシステムはビット単位で同一。加えて `nix flake check` を実行する。

## スコープ外

- 設定値の変更・改善(パッケージの追加削除、オプション値の変更)
- darwin/common.nix と linux/common.nix の内部分割
- 新ホスト・新ユーザーの追加
