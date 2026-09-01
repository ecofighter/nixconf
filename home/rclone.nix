{ pkgs, config, ... }:

{
  programs.rclone = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    remotes = {
      onedrive = {
        config = {
          type = "onedrive";
          drive_type = "personal";
        };
        secrets = {
          token = config.sops.secrets.rclone_onedrive_token.path;
          drive_id = config.sops.secrets.rclone_onedrive_drive_id.path;
        };
      };
    };
  };
  systemd.user.services."rclone-mount@onedrive" = {
    Unit = {
      Description = "Rclone FUSE daemon for onedrive:";
      After = [
        "rclone-config.service"
        "network-online.target"
      ];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/OneDrive";
      ExecStart = "${pkgs.rclone}/bin/rclone mount --cache-dir %C --vfs-cache-mode full onedrive: %h/OneDrive";
      Restart = "on-failure";
      Environment = "PATH=/run/wrappers/bin";
      ExecStop = "fusermount -u %h/OneDrive";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
