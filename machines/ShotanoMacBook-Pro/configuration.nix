{
  self,
  pkgs,
  config,
  ...
}:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  system.primaryUser = "arakaki";
  environment.systemPackages = with pkgs; [
    vim
    go
    texliveFull
    texlab
  ];
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
    };
    # nix-homebrew の宣言済み tap を nix-darwin 側が再 tap しないようにする
    taps = builtins.attrNames config.nix-homebrew.taps;
    brews = [
      "pympress"
      "container"
    ];
    casks = [
      "1password"
      "1password-cli"
      "macskk"
      "karabiner-elements"
      "onedrive"
      "microsoft-outlook"
      "microsoft-excel"
      "microsoft-teams"
      "microsoft-word"
      "zoom"
      "obs"
      "visual-studio-code"
      "discord"
      "docker-desktop"
      "jabref"
      "codex-app"
    ];
  };
  fonts = {
    packages = with pkgs; [
      _0xproto
      ibm-plex
    ];
  };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
}
