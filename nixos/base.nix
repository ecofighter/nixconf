# NixOS のシステム層のうち、GUI の有無を問わずどのマシンにも必要なもの。
# グラフィカルセッション前提のものは desktop.nix、ハードウェアやホスト固有のものは machines/<host>/default.nix に置く。
# 非 NixOS のスタンドアロン構成 (mkHome) はこの層を読まないので、そちらにも要るものは home/ に置く
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

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
  ];
}
