{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.programs.noisetorch;
in
{
  options.programs.noisetorch = {
    enable = mkEnableOption (mdDoc "noisetorch + setcap wrapper");

    package = mkPackageOption pkgs "noisetorch" { };
  };

  config = mkIf cfg.enable {
    security.wrappers.noisetorch = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_resource=+ep";
      source = "${cfg.package}/bin/noisetorch";
    };
    environment.systemPackages = [ cfg.package ];
  };
}
