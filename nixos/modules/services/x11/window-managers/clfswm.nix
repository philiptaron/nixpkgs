{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    singleton
    ;

  cfg = config.services.xserver.windowManager.clfswm;
in

{
  options = {
    services.xserver.windowManager.clfswm = {
      enable = mkEnableOption (mdDoc "clfswm");
      package = mkPackageOption pkgs [ "lispPackages" "clfswm" ] { };
    };
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "clfswm";
      start = ''
        ${cfg.package}/bin/clfswm &
        waitPID=$!
      '';
    };
    environment.systemPackages = [ cfg.package ];
  };
}
