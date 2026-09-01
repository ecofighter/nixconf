{
  lib,
  pkgs,
  emacs-conf,
  lean4-mode,
  ...
}:

let
  emacsBase = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;
  lean4ModeFor =
    epkgs:
    epkgs.melpaBuild {
      pname = "lean4-mode";
      version = "${builtins.substring 0 8 lean4-mode.lastModifiedDate}.0";
      src = lean4-mode;
      files = ''(:defaults "data")'';
      packageRequires = with epkgs; [
        compat
        dash
        magit-section
        lsp-mode
      ];
      meta.description = "Emacs major mode for Lean 4";
    };
  emacsFromUsePackage = pkgs.emacsWithPackagesFromUsePackage {
    config = "${emacs-conf}/init.el";
    defaultInitFile = false;
    alwaysEnsure = false;
    package = emacsBase;
  };
in
{
  xdg.configFile."emacs" = {
    source = emacs-conf;
    recursive = true;
  };
  programs.emacs = {
    enable = true;
    package = emacsBase;
    # パッケージ集合の情報源は init.el の `:ensure' 一本にする。
    # ここで足すのは use-package では宣言しようがないものだけ:
    #   - lean4-mode: nixpkgs に無いので個別にビルドする (init.el からは :ensure nil で参照)
    #   - tree-sitter grammar: elisp パッケージではなく、.so を treesit-extra-load-path に載せるもの
    extraPackages =
      epkgs:
      lib.filter (p: p != null) emacsFromUsePackage.explicitRequires
      ++ [
        (lean4ModeFor epkgs)
        (epkgs.treesit-grammars.with-grammars (
          g: with g; [
            tree-sitter-c
            tree-sitter-cpp
            tree-sitter-rust
            tree-sitter-go
            tree-sitter-gomod
            tree-sitter-python
            tree-sitter-markdown
            tree-sitter-markdown-inline
            tree-sitter-typst
            tree-sitter-nix
          ]
        ))
      ];
  };
}
