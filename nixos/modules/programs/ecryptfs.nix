{ config, lib, pkgs, ... }:

let
  inherit (lib)
    getBin
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.ecryptfs;
in
{
  options.programs.ecryptfs = {
    enable = mkEnableOption (mdDoc "ecryptfs setuid mount wrappers");
  };

  config = mkIf cfg.enable {
    security.wrappers = {

      "mount.ecryptfs_private" = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${getBin pkgs.ecryptfs}/bin/mount.ecryptfs_private";
      };
      "umount.ecryptfs_private" = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${getBin pkgs.ecryptfs}/bin/umount.ecryptfs_private";
      };

    };
  };
}
