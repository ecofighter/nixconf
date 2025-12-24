{ self, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  system.primaryUser = "arakaki";
  environment.systemPackages = with pkgs; [
    vim
    texliveFull
    vscode
  ];
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    casks = [
      "macskk"
      "karabiner-elements"
      "onedrive"
      "microsoft-outlook"
      "microsoft-excel"
      "microsoft-teams"
      "zoom"
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
