{ pkgs, username, ... }:

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

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
