{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.afterstep;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.afterstep.enable = mkEnableOption (mdDoc "afterstep");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "afterstep";
      start = ''
        ${pkgs.afterstep}/bin/afterstep &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.afterstep ];
  };
}
