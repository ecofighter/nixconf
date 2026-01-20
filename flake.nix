{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      plasma-manager,
      ...
    }:
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
          };
          pkgs = import nixpkgs {
            system = "x86_64-linux";
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
