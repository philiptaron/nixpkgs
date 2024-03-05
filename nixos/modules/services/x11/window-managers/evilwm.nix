{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.evilwm;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.evilwm.enable = mkEnableOption (mdDoc "evilwm");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "evilwm";
      start = ''
        ${pkgs.evilwm}/bin/evilwm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.evilwm ];
  };
}
