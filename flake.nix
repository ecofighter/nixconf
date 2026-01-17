{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
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
      plasma-manager,
      ...
    }:
    {
      nixosConfigurations = {
        "schwertleite" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self; };
          system = "x86_64-linux";
          modules = [
            ./machines/schwertleite/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { isNixOS = true; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              home-manager.backupFileExtension = "backup";
              home-manager.users.arakaki = {
                imports = [ ./home.nix ];
                home.username = "arakaki";
                home.homeDirectory = "/home/arakaki";
              };
            }
          ];
        };
      };

      darwinConfigurations = {
        "ShotanoMacBook-Pro" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit self; };
          modules = [
            ./machines/ShotanoMacBook-Pro/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.extraSpecialArgs = { isNixOS = false; };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
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

      homeConfigurations."haneta" = home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = { isNixOS = false; };
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        modules = [
          plasma-manager.homeModules.plasma-manager
          {
            targets.genericLinux.enable = true;
            nixpkgs = {
              config.allowUnfree = true;
            };
            home.username = "haneta";
            home.homeDirectory = "/home/haneta";
          }
          ./home.nix
        ];
      };
    };
}
