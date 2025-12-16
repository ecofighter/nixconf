{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, ... }:
  let
    lib = nixpkgs.lib;
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      system.primaryUser = "arakaki";
      environment.systemPackages =
        with pkgs; [
          vim
          texliveFull
          vscode
        ];
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "uninstall";
        };
        casks = [
          "macskk"
          "karabiner-elements"
          "onedrive"
          "microsoft-outlook"
          "microsoft-excel"
          "microsoft-teams"
          "zoom"
        ];
      };
      fonts = {
        packages = with pkgs; [
          _0xproto
          ibm-plex
        ];
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      programs.zsh.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#ShotanoMacBook-Pro
    darwinConfigurations."ShotanoMacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";

          users.users.arakaki.home = "/Users/arakaki";
          home-manager.users.arakaki = {
            imports = [ ./home.nix ];
            home.username = "arakaki";
            home.homeDirectory = "/Users/arakaki";
          };
        }
      ];
    };
  };
}
