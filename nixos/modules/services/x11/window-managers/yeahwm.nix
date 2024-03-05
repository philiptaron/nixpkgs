{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.yeahwm;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.yeahwm.enable = mkEnableOption (mdDoc "yeahwm");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "yeahwm";
      start = ''
        ${pkgs.yeahwm}/bin/yeahwm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.yeahwm ];
  };
}
