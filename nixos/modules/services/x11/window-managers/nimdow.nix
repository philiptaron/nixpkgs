{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.nimdow;
in
{
  options = {
    services.xserver.windowManager.nimdow.enable = mkEnableOption (mdDoc "nimdow");
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "nimdow";
      start = ''
        ${pkgs.nimdow}/bin/nimdow &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.nimdow ];
  };
}
