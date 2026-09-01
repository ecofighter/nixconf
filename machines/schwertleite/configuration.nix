{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../linux/common.nix
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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;

  networking.hostName = "schwertleite";

  services.kmscon = {
    enable = false;
    useXkbConfig = true;
  };

  services.fprintd.enable = true;
  security.pam.services = {
    login.fprintAuth = false;
    sudo.fprintAuth = true;
  };

  system.stateVersion = "26.05";
}
