{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.hackedbox;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.hackedbox.enable = mkEnableOption (mdDoc "hackedbox");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "hackedbox";
      start = ''
        ${pkgs.hackedbox}/bin/hackedbox &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ pkgs.hackedbox ];
  };
}
