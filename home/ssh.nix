{
  lib,
  pkgs,
  isNixOS,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  # Linux の agent は NixOS の programs._1password-gui が提供するため isNixOS に限定する
  programs.ssh = lib.mkIf (isDarwin || isNixOS) {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      IdentityAgent =
        if isDarwin then
          "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
        else
          "~/.1password/agent.sock";
    };
  };
}
