{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{

  ###### interface

  options = {

    programs.system-config-printer = {

      enable = mkEnableOption (mdDoc "system-config-printer, a Graphical user interface for CUPS administration");

    };

  };


  ###### implementation

  config = mkIf config.programs.system-config-printer.enable {

    environment.systemPackages = [
      pkgs.system-config-printer
    ];

    services.system-config-printer.enable = true;

  };

}
