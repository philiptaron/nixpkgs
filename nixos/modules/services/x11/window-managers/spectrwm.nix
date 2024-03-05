
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.xserver.windowManager.spectrwm;
in

{
  options = {
    services.xserver.windowManager.spectrwm.enable = mkEnableOption (mdDoc "spectrwm");
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager = {
      session = [{
        name = "spectrwm";
        start = ''
          ${pkgs.spectrwm}/bin/spectrwm &
          waitPID=$!
        '';
      }];
    };
    environment.systemPackages = [ pkgs.spectrwm ];
  };
}
