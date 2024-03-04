{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.sysdig;
in
{
  options.programs.sysdig.enable = mkEnableOption (mdDoc "sysdig");

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sysdig ];
    boot.extraModulePackages = [ config.boot.kernelPackages.sysdig ];
  };
}
