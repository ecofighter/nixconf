{ lib, pkgs, ... }:

{
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
      sops
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
      texliveFull
      texlab
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      wl-clipboard
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      container
      pympress
      zoom-us
      _1password-cli
    ];
}
