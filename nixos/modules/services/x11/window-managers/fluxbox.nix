{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.fluxbox;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.fluxbox.enable = mkEnableOption (mdDoc "fluxbox");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "fluxbox";
      start = ''
        ${pkgs.fluxbox}/bin/startfluxbox &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.fluxbox ];
  };
}
