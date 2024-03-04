{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.flashrom;
in
{
  options.programs.flashrom = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Installs flashrom and configures udev rules for programmers
        used by flashrom. Grants access to users in the "flashrom"
        group.
      '';
    };
    package = mkPackageOption pkgs "flashrom" { };
  };

  config = mkIf cfg.enable {
    services.udev.packages = [ cfg.package ];
    environment.systemPackages = [ cfg.package ];
  };
}
