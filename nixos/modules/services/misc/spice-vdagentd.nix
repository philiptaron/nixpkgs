{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.spice-vdagentd;
in
{
  options = {
    services.spice-vdagentd = {
      enable = mkEnableOption (mdDoc "Spice guest vdagent daemon");
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.spice-vdagent ];

    systemd.services.spice-vdagentd = {
      description = "spice-vdagent daemon";
      wantedBy = [ "graphical.target" ];
      preStart = ''
        mkdir -p "/run/spice-vdagentd/"
      '';
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagentd";
      };
    };
  };
}
