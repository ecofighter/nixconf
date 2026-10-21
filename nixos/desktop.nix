{ pkgs, username, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-skk-qt
    ];
    fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "jp";
        DefaultIM = "skk";
      };
      "Groups/0/Items/0".Name = "keyboard-jp";
      "Groups/0/Items/1".Name = "skk";
    };
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

  programs.firefox = {
    enable = true;
    languagePacks = [ "ja" ];
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };

  programs.zoom-us.enable = true;
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };
}
