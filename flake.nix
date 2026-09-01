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
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
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
    inputs:
    let
      hosts = import ./lib inputs;
    in
    {
      nixosConfigurations = {
        "schwertleite" = hosts.mkNixosHost ./machines/schwertleite/configuration.nix;
      };

      darwinConfigurations = {
        "alice" = hosts.mkDarwinHost ./machines/alice;
        "ShotanoMacBook-Pro" = hosts.mkDarwinHost ./machines/shotano-macbook-pro;
      };

      homeConfigurations."haneta" = hosts.mkHome { username = "haneta"; };
    };
}
