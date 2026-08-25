{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs-conf = {
      url = "github:ecofighter/.emacs.d";
      flake = false;
    };
    # nixpkgs に無いため個別に供給する (init.el からは :ensure nil で参照)
    lean4-mode = {
      url = "github:leanprover-community/lean4-mode";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      plasma-manager,
      emacs-overlay,
      emacs-conf,
      lean4-mode,
      ...
    }:
    let
      overlays = [ emacs-overlay.overlays.default ];
    in
    {
      nixosConfigurations = {
        "schwertleite" =
          let
            username = "arakaki";
            homeDir = "/home/${username}";
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = { inherit self; };
            system = "x86_64-linux";
            modules = [
              ./machines/schwertleite/configuration.nix
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
                home-manager.extraSpecialArgs = {
                  isNixOS = true;
                  inherit emacs-conf lean4-mode;
                };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  sops-nix.homeManagerModules.sops
                  plasma-manager.homeModules.plasma-manager
                ];
                home-manager.users.arakaki = {
                  imports = [ ./home.nix ];
                  home.username = username;
                  home.homeDirectory = homeDir;
                };
              }
            ];
          };
      };

      darwinConfigurations = {
        "alice" =
          let
            username = "arakaki";
            homeDir = "/Users/${username}";
          in
          nix-darwin.lib.darwinSystem {
            specialArgs = { inherit self; };
            modules = [
              ./machines/alice/configuration.nix
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
                home-manager.extraSpecialArgs = {
                  isNixOS = false;
                  inherit emacs-conf lean4-mode;
                };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  sops-nix.homeManagerModules.sops
                  plasma-manager.homeModules.plasma-manager
                ];
                users.users.arakaki.home = "/Users/arakaki";
                home-manager.users.arakaki = {
                  imports = [ ./home.nix ];
                  home.username = username;
                  home.homeDirectory = homeDir;
                };
              }
            ];
          };
        "ShotanoMacBook-Pro" =
          let
            username = "arakaki";
            homeDir = "/Users/${username}";
          in
          nix-darwin.lib.darwinSystem {
            specialArgs = { inherit self; };
            modules = [
              ./machines/ShotanoMacBook-Pro/configuration.nix
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
                home-manager.extraSpecialArgs = {
                  isNixOS = false;
                  inherit emacs-conf lean4-mode;
                };
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  sops-nix.homeManagerModules.sops
                  plasma-manager.homeModules.plasma-manager
                ];
                users.users.arakaki.home = "/Users/arakaki";
                home-manager.users.arakaki = {
                  imports = [ ./home.nix ];
                  home.username = username;
                  home.homeDirectory = homeDir;
                };
              }
            ];
          };
      };

      homeConfigurations."haneta" =
        let
          username = "haneta";
          homeDir = "/home/${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = {
            isNixOS = false;
            inherit emacs-conf lean4-mode;
          };
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            inherit overlays;
          };
          modules = [
            sops-nix.homeManagerModules.sops
            plasma-manager.homeModules.plasma-manager
            {
              targets.genericLinux.enable = true;
              nixpkgs = {
                config.allowUnfree = true;
              };
              home.username = username;
              home.homeDirectory = homeDir;
            }
            ./home.nix
          ];
        };
    };
}
