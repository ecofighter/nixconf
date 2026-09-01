{ pkgs, config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";
    history.size = 10000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [
      "rm *"
      "cp *"
    ];
    siteFunctions = {
      emc = ''
        emacs -nw "$@"
      '';
      emg =
        if pkgs.stdenv.hostPlatform.isDarwin then
          # `open -a Emacs' は解決を LaunchServices の登録に任せてしまう。
          # 古い世代の *ラップされていない* Emacs.app が登録に残っていると
          # そちらが起動し、emacsWithPackages が設定する EMACSLOADPATH を
          # 通らないので Nix 由来のパッケージが load-path に入らない。すると
          # init.el の `:ensure' が全部未インストール扱いになり、起動のたびに
          # ELPA から `package-user-dir' へダウンロードが走る。
          # バンドルをパスで直接指定して、必ずラッパー入りのものを起動する。
          ''
            open -a "${config.programs.emacs.finalPackage}/Applications/Emacs.app" "$@"
          ''
        else
          ''
            nohup emacs "$@" >/dev/null 2>&1 &
            disown
          '';
    };
    shellAliases = {
      em = "emg";
    };
    localVariables = {
      ZSH_AUTOSUGGEST_STRATEGY = [
        "completion"
        "history"
      ];
    };
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      }
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
      }
    ];
  };
}
