{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.hypr;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.hypr.enable = mkEnableOption (mdDoc "hypr");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "hypr";
      start = ''
        ${pkgs.hypr}/bin/Hypr &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.hypr ];
  };
}
