{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    ;
in

{
  config = mkIf (config.boot.supportedFilesystems.glusterfs or false) {

    system.fsPackages = [ pkgs.glusterfs ];

  };
}
