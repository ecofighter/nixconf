{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  services.resolved.enable = true;
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocales = [ "en_US.UTF-8/UTF-8" ];
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-skk-qt
    ];
  };
  fonts = {
    packages = with pkgs; [
      noto-fonts
      ibm-plex
      twemoji-color-font
    ];
    fontDir.enable = true;
    fontconfig = {
      defaultFonts = {
        serif = [ "IBM Plex Serif JP" ];
        sansSerif = [ "IBM Plex Sans JP" ];
        monospace = [ "IBM Plex Mono" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };

  services.xserver.enable = false;
  services.displayManager.plasma-login-manager.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb.layout = "jp";
  services.xserver.xkb.options = "ctrl:nocaps";

  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.arakaki = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  programs.git.enable = true;
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override {
      ffmpegSupport = true;
      pipewireSupport = true;
    }) {};
    languagePacks = [ "ja" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
