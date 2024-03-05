{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.smallwm;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.smallwm.enable = mkEnableOption (mdDoc "smallwm");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "smallwm";
      start = ''
        ${pkgs.smallwm}/bin/smallwm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.smallwm ];
  };
}
