{
  self,
  config,
  ...
}:

{
  system.primaryUser = "arakaki";

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
    };
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [ ];
    # nixpkgs に無い、または cask がシステム統合 (インプットメソッド登録・
    # システム機能拡張・/Applications 配置) を担うものだけを残す。
    casks = [
      "macskk"
      "karabiner-elements"
      "onedrive"
      "microsoft-outlook"
      "microsoft-excel"
      "microsoft-teams"
      "microsoft-word"
      "obs"
      "jabref"
      "1password"
      "docker-desktop"
      "codex-app"
    ];
  };

  nix.settings.experimental-features = "nix-command flakes";

  programs.zsh.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
}
