{ config, ... }:

{
  imports = [ ];

  home.stateVersion = "26.05";

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  programs.home-manager.enable = true;
}
