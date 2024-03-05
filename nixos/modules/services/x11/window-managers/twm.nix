{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.twm;

in

{

  ###### interface

  options = {
    services.xserver.windowManager.twm.enable = mkEnableOption (mdDoc "twm");
  };


  ###### implementation

  config = mkIf cfg.enable {

    services.xserver.windowManager.session = singleton
      { name = "twm";
        start =
          ''
            ${pkgs.xorg.twm}/bin/twm &
            waitPID=$!
          '';
      };

    environment.systemPackages = [ pkgs.xorg.twm ];

  };

}
