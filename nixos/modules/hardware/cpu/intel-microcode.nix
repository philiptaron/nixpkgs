{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkOrder
    types
    ;
in

{

  ###### interface

  options = {

    hardware.cpu.intel.updateMicrocode = mkOption {
      default = false;
      type = types.bool;
      description = mdDoc ''
        Update the CPU microcode for Intel processors.
      '';
    };

  };


  ###### implementation

  config = mkIf config.hardware.cpu.intel.updateMicrocode {
    # Microcode updates must be the first item prepended in the initrd
    boot.initrd.prepend = mkOrder 1 [ "${pkgs.microcodeIntel}/intel-ucode.img" ];
  };

}
