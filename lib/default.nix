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
    # sops-nix
    plasma-manager
    emacs-overlay
    emacs-conf
    lean4-mode
    nix-homebrew
    homebrew-core
    homebrew-cask
    homebrew-anthropics
    ;

  # ユーザー固有の値 (git identity、home.stateVersion など) は home/users/<username>.nix に置く。
  # 全 builder がこのファイルを必須として import する。共有の home/<feature>.nix にはユーザー固有の値を書かない
  userModule = username: ../home/users + "/${username}.nix";

  overlays = [ emacs-overlay.overlays.default ];

  hmSharedModules = [
    # sops-nix.homeManagerModules.sops
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
          "anthropics/homebrew-tap" = homebrew-anthropics;
        };
        mutableTaps = false;
        enableZshIntegration = true;
      };
    }
  ];
in
{
  # NixOS ホストの追加手順:
  #   1. machines/<host>/ に生成された hardware-configuration.nix を置く (nixpkgs.hostPlatform が無ければ default.nix で設定)
  #   2. machines/<host>/default.nix で ../../nixos/base.nix と、GUI 機なら ../../nixos/desktop.nix を import し、
  #      hostName・boot・system.stateVersion などホスト固有の設定を書く
  #   3. flake.nix に mkNixosHost { machine = ./machines/<host>; } を追加する。arakaki 以外なら username を渡し、
  #      home/users/<username>.nix (home.stateVersion を含む) を作る
  mkNixosHost =
    {
      machine,
      username ? "arakaki",
    }:
    let
      homeDir = "/home/${username}";
    in
    assert
      builtins.pathExists (userModule username) || throw "nixconf: missing home/users/${username}.nix";
    nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self username; };
      modules = [
        machine
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
            imports = [
              ../home
              (userModule username)
            ];
            home.username = username;
            home.homeDirectory = homeDir;
          };
        }
      ];
    };

  mkDarwinHost =
    machine:
    let
      username = "arakaki";
      homeDir = "/Users/${username}";
    in
    nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self; };
      modules = nixHomebrewModules ++ [
        machine
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
            imports = [
              ../home
              (userModule username)
            ];
            home.username = username;
            home.homeDirectory = homeDir;
          };
        }
      ];
    };

  # 非 NixOS の Linux 向けスタンドアロン構成。保証するのは評価が通ることまで。
  # - home/ の isLinux 項目は、Nix のクロージャで完結し mkHome で評価できればここにも入れる
  # - NixOS 層 (nixos/ や /run/current-system) に依存するもの、評価できないものは isNixOS に絞る
  # - スタンドアロン向けの補完は、HM オプションの既定値が nixosConfig に依存して
  #   NixOS とここで値が食い違う場合に限り、lib.mkIf (isLinux && !isNixOS) で入れる
  mkHome =
    {
      username,
      system ? "x86_64-linux",
    }:
    let
      homeDir = "/home/${username}";
    in
    assert
      builtins.pathExists (userModule username) || throw "nixconf: missing home/users/${username}.nix";
    home-manager.lib.homeManagerConfiguration {
      extraSpecialArgs = mkExtraSpecialArgs false;
      pkgs = import nixpkgs {
        inherit system;
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
        (userModule username)
      ];
    };
}
