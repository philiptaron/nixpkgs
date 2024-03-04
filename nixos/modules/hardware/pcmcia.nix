{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  pcmciaUtils = pkgs.pcmciaUtils.passthru.function {
    inherit (config.hardware.pcmcia) firmware config;
  };
in

{
  ###### interface

  options = {

    hardware.pcmcia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable this option to support PCMCIA card.
        '';
      };

      firmware = mkOption {
        type = types.listOf types.path;
        default = [];
        description = mdDoc ''
          List of firmware used to handle specific PCMCIA card.
        '';
      };

      config = mkOption {
        default = null;
        type = types.nullOr types.path;
        description = mdDoc ''
          Path to the configuration file which maps the memory, IRQs
          and ports used by the PCMCIA hardware.
        '';
      };
    };

  };

  ###### implementation

  config = mkIf config.hardware.pcmcia.enable {

    boot.kernelModules = [ "pcmcia" ];

    services.udev.packages = [ pcmciaUtils ];

    environment.systemPackages = [ pcmciaUtils ];

  };

}
