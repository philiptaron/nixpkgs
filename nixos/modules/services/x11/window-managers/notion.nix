{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.xserver.windowManager.notion;
in

{
  options = {
    services.xserver.windowManager.notion.enable = mkEnableOption (mdDoc "notion");
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager = {
      session = [{
        name = "notion";
        start = ''
          ${pkgs.notion}/bin/notion &
          waitPID=$!
        '';
      }];
    };
    environment.systemPackages = [ pkgs.notion ];
  };
}
