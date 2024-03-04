{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.programs.flexoptix-app;
in
{
  options = {
    programs.flexoptix-app = {
      enable = mkEnableOption (mdDoc "FLEXOPTIX app + udev rules");

      package = mkPackageOption pkgs "flexoptix-app" { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.udev.packages = [ cfg.package ];
  };
}
