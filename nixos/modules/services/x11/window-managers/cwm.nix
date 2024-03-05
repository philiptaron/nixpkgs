{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.cwm;
in
{
  options = {
    services.xserver.windowManager.cwm.enable = mkEnableOption (mdDoc "cwm");
  };
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton
      { name = "cwm";
        start =
          ''
            cwm &
            waitPID=$!
          '';
      };
    environment.systemPackages = [ pkgs.cwm ];
  };
}
