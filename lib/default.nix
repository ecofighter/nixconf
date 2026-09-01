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
