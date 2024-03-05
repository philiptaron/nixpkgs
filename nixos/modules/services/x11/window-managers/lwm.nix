{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.lwm;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.lwm.enable = mkEnableOption (mdDoc "lwm");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "lwm";
      start = ''
        ${pkgs.lwm}/bin/lwm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.lwm ];
  };
}
