{ config, lib, pkgs, ... }:

{
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  fileSystems = {
    "/nix".options = [ "compress=zstd" "noatime" ];
    "/swap".options = [ "noatime" ];
   };
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16*1024;
    }
  ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use zen kernel.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  networking.hostName = "schwertleite";

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
  services.kmscon = {
    enable = true;
    useXkbConfig = true;
  };

  services.xserver.enable = false;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb.layout = "jp";
  services.xserver.xkb.options = "ctrl:nocaps";

  services.fprintd.enable = true;
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

  system.stateVersion = "25.11";
}
