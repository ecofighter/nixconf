{ config, ... }:

{
  imports = [
    # ./sops.nix
    ./packages.nix
    ./zsh.nix
    ./starship.nix
    ./cli-tools.nix
    ./ssh.nix
    ./emacs.nix
    ./ghostty.nix
    # rclone の OneDrive 認証情報は sops に依存するため sops と一緒に無効化
    # ./rclone.nix
    ./mpv.nix
    ./plasma.nix
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  programs.home-manager.enable = true;
}
