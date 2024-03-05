{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    ;
in

{
  config = mkIf (config.boot.supportedFilesystems.exfat or false) {
    system.fsPackages = if config.boot.kernelPackages.kernelOlder "5.7" then [
      pkgs.exfat # FUSE
    ] else [
      pkgs.exfatprogs # non-FUSE
    ];
  };
}
