{ config, ... }:

{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      rclone_onedrive_token = {
        sopsFile = ../secrets/rclone_onedrive_token.bin;
        format = "binary";
      };
      rclone_onedrive_drive_id = {
        sopsFile = ../secrets/rclone_onedrive_drive_id.bin;
        format = "binary";
      };
    };
  };
}
