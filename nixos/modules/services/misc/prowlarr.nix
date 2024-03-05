{ config, pkgs, lib, ... }:

let
  inherit (lib)
    getExe
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.prowlarr;

in
{
  options = {
    services.prowlarr = {
      enable = mkEnableOption (mdDoc "Prowlarr");

      package = mkPackageOption pkgs "prowlarr" { };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Open ports in the firewall for the Prowlarr web interface.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.prowlarr = {
      description = "Prowlarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        StateDirectory = "prowlarr";
        ExecStart = "${getExe cfg.package} -nobrowser -data=/var/lib/prowlarr";
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 9696 ];
    };
  };
}
