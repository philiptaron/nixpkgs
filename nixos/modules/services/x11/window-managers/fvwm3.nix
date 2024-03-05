{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.fvwm3;
  inherit (pkgs) fvwm3;
in

{

  ###### interface

  options = {
    services.xserver.windowManager.fvwm3 = {
      enable = mkEnableOption (mdDoc "Fvwm3 window manager");
    };
  };


  ###### implementation

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton
      { name = "fvwm3";
        start =
          ''
            ${fvwm3}/bin/fvwm3 &
            waitPID=$!
          '';
      };

    environment.systemPackages = [ fvwm3 ];
  };
}
