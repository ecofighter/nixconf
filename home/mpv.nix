{ pkgs, ... }:

{
  programs.mpv = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    config = {
      profile = "gpu-hq";
      force-window = true;
      autofit-larger = "1280x720";
      autofit-smaller = "640x360";
    };
    scripts = with pkgs.mpvScripts; [
      mpris
    ];
  };
}
