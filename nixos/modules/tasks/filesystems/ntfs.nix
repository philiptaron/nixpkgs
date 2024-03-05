{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    ;
in

{
  config = mkIf (config.boot.supportedFilesystems.ntfs or config.boot.supportedFilesystems.ntfs-3g or false) {

    system.fsPackages = [ pkgs.ntfs3g ];

  };
}
