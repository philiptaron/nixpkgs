{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.hardware.spacenavd;

in
{

  options = {
    hardware.spacenavd = {
      enable = mkEnableOption (mdDoc "spacenavd to support 3DConnexion devices");
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.spacenavd = {
      description = "Daemon for the Spacenavigator 6DOF mice by 3Dconnexion";
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.spacenavd}/bin/spacenavd -d -l syslog";
      };
    };
  };
}
