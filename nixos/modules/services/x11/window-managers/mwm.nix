{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.mwm;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.mwm.enable = mkEnableOption (mdDoc "mwm");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "mwm";
      start = ''
        ${pkgs.motif}/bin/mwm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.motif ];
  };
}
