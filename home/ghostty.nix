{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package =
      if pkgs.stdenv.hostPlatform.isLinux then
        pkgs.ghostty
      else if pkgs.stdenv.hostPlatform.isDarwin then
        pkgs.ghostty-bin
      else
        throw "unsupported system ${pkgs.stdenv.hostPlatform.system}";
    enableZshIntegration = true;

    settings = {
      font-family = [
        "IBM Plex Mono"
        "IBM Plex Sans JP"
      ];
      font-feature = "-dlig";
      theme = "Kanagawa Wave";
      keybind = "shift+enter=text:\\n";
      background-opacity = 0.9;
      window-decoration = "auto";
    };
  };
}
