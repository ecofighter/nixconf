{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      "schwertleite" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./schwertleite/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.arakaki = {
              imports = [ ../home.nix ];
              home.username = "arakaki";
              home.homeDirectory = "/home/arakaki";
            };
          }
        ];
      };
    };
  };
}

