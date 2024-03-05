{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.sawfish;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.sawfish.enable = mkEnableOption (mdDoc "sawfish");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "sawfish";
      start = ''
        ${pkgs.sawfish}/bin/sawfish &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.sawfish ];
  };
}
