{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.tinywm;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.tinywm.enable = mkEnableOption (mdDoc "tinywm");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "tinywm";
      start = ''
        ${pkgs.tinywm}/bin/tinywm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.tinywm ];
  };
}
