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
    brews = [
      "container"
      "pympress"
    ];
    casks = [
      "macskk"
      "karabiner-elements"
      "onedrive"
      "microsoft-outlook"
      "microsoft-excel"
      "microsoft-teams"
      "microsoft-word"
      "zoom"
      "obs"
      "discord"
      "jabref"
      "1password"
      "1password-cli"
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
