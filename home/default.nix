{ config, ... }:

{
  imports = [
    ./sops.nix
    ./packages.nix
    ./zsh.nix
    ./starship.nix
    ./cli-tools.nix
    ./ghostty.nix
  ];

  home.stateVersion = "26.05";

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  programs.home-manager.enable = true;
}
