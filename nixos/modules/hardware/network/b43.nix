{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  kernelVersion = config.boot.kernelPackages.kernel.version;
in

{

  ###### interface

  options = {

    networking.enableB43Firmware = mkOption {
      default = false;
      type = types.bool;
      description = mdDoc ''
        Turn on this option if you want firmware for the NICs supported by the b43 module.
      '';
    };

  };


  ###### implementation

  config = mkIf config.networking.enableB43Firmware {
    hardware.firmware = [ pkgs.b43Firmware_5_1_138 ];
  };

}
