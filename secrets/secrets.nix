let
  schwertleite = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQwQo4sWMxuMvTykhzzz/uFlZ2ze3kgDRhbSKhNppLc";
in {
  "rclone.onedrive.token.age".publicKeys = [ schwertleite ];
  "rclone.onedrive.drive_id.age".publicKeys = [ schwertleite ];
}
