# List all devices which are detected by nixos-generate-config.
# Common devices are enabled by default.
{ lib, ... }:

let
  inherit (lib)
    mkDefault
    ;
in

{
  config = mkDefault {
    # Common firmware, i.e. for wifi cards
    hardware.enableRedistributableFirmware = true;
  };
}
