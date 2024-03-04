{ config, lib, pkgs, ... }:

let
  inherit (lib)
    getBin
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.udevil;
in
{
  options.programs.udevil.enable = mkEnableOption (mdDoc "udevil");

  config = mkIf cfg.enable {
    security.wrappers.udevil =
      { setuid = true;
        owner = "root";
        group = "root";
        source = "${getBin pkgs.udevil}/bin/udevil";
      };
  };
}
