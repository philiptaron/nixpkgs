{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.hardware.digitalbitbox;
in

{
  options.hardware.digitalbitbox = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enables udev rules for Digital Bitbox devices.
      '';
    };

    package = mkPackageOption pkgs "digitalbitbox" {
      extraDescription = ''
        This can be used to install a package with udev rules that differ from the defaults.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.udev.packages = [ cfg.package ];
  };
}
