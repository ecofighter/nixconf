{
  lib,
  pkgs,
  isNixOS,
  ...
}:

{
  # NixOS では HM の既定値が nixos 側の fontconfig を引き継いで true になるが、
  # スタンドアロン (非 NixOS) では false のままで home.packages のフォントが見えないため補う
  fonts.fontconfig.enable = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && !isNixOS) true;

  home.packages =
    with pkgs;
    [
      ibm-plex
      _0xproto
      nerd-fonts.symbols-only
      zsh-completions
      nixfmt
      nixd
      age
      # sops
      ripgrep
      gh
      devcontainer
      pandoc
      (hunspell.withDicts (d: with d; [ en_US-large ]))
      slack
      glibtool
      cmake
      poppler-utils
      typst
      tinymist
      typstyle
      go
      python3
      texliveFull
      texlab
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      wl-clipboard
      discord
      libreoffice-qt
      pympress
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      container
      pympress
      zoom-us
      _1password-cli
    ];
}
