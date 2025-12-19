{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    {
      nixosConfigurations = {
        "schwertleite" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/schwertleite/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
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
          modules = [
            ./machines/ShotanoMacBook-Pro/configuration.nix
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
    };
}
