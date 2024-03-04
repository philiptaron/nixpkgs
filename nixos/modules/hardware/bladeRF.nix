{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.hardware.bladeRF;
in

{
  options.hardware.bladeRF = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enables udev rules for BladeRF devices. By default grants access
        to users in the "bladerf" group. You may want to install the
        libbladeRF package.
      '';
    };

  };

  config = mkIf cfg.enable {
    services.udev.packages = [ pkgs.libbladeRF ];
    users.groups.bladerf = {};
  };
}
