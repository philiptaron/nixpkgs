{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager."2bwm";

in

{

  ###### interface

  options = {
    services.xserver.windowManager."2bwm".enable = mkEnableOption (mdDoc "2bwm");
  };


  ###### implementation

  config = mkIf cfg.enable {

    services.xserver.windowManager.session = singleton
      { name = "2bwm";
        start =
          ''
            ${pkgs._2bwm}/bin/2bwm &
            waitPID=$!
          '';
      };

    environment.systemPackages = [ pkgs._2bwm ];

  };

}
