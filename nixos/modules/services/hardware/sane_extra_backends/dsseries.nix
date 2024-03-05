{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{
  options = {

    hardware.sane.dsseries.enable =
      mkEnableOption (mdDoc "Brother DSSeries scan backend") // {
      description = mdDoc ''
        When enabled, will automatically register the "dsseries" SANE backend.

        This supports the Brother DSmobile scanner series, including the
        DS-620, DS-720D, DS-820W, and DS-920DW scanners.
      '';
    };
  };

  config = mkIf (config.hardware.sane.enable && config.hardware.sane.dsseries.enable) {

    hardware.sane.extraBackends = [ pkgs.dsseries ];
    services.udev.packages = [ pkgs.dsseries ];
    boot.kernelModules = [ "sg" ];

  };
}
