{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.services.xserver.windowManager.ragnarwm;
in
{
  ###### interface

  options = {
    services.xserver.windowManager.ragnarwm = {
      enable = mkEnableOption (mdDoc "ragnarwm");
      package = mkPackageOption pkgs "ragnarwm" { };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    services.xserver.displayManager.sessionPackages = [ cfg.package ];
    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with maintainers; [ sigmanificient ];
}
