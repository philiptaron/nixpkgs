{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkRenamedOptionModule
    singleton
    types
    ;

  cfg = config.services.xserver.windowManager.fvwm2;
  fvwm2 = pkgs.fvwm2.override { enableGestures = cfg.gestures; };
in

{

  imports = [
    (mkRenamedOptionModule
      [ "services" "xserver" "windowManager" "fvwm" ]
      [ "services" "xserver" "windowManager" "fvwm2" ])
  ];

  ###### interface

  options = {
    services.xserver.windowManager.fvwm2 = {
      enable = mkEnableOption (mdDoc "Fvwm2 window manager");

      gestures = mkOption {
        default = false;
        type = types.bool;
        description = mdDoc "Whether or not to enable libstroke for gesture support";
      };
    };
  };


  ###### implementation

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton
      { name = "fvwm2";
        start =
          ''
            ${fvwm2}/bin/fvwm &
            waitPID=$!
          '';
      };

    environment.systemPackages = [ fvwm2 ];
  };
}
