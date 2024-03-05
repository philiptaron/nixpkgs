{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.heartbeat;

  heartbeatYml = pkgs.writeText "heartbeat.yml" ''
    name: ${cfg.name}
    tags: ${builtins.toJSON cfg.tags}

    ${cfg.extraConfig}
  '';

in
{
  options = {

    services.heartbeat = {

      enable = mkEnableOption (mdDoc "heartbeat");

      package = mkPackageOption pkgs "heartbeat" {
        example = "heartbeat7";
      };

      name = mkOption {
        type = types.str;
        default = "heartbeat";
        description = mdDoc "Name of the beat";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = mdDoc "Tags to place on the shipped log messages";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/heartbeat";
        description = mdDoc "The state directory. heartbeat's own logs and other data are stored here.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = ''
          heartbeat.monitors:
          - type: http
            urls: ["http://localhost:9200"]
            schedule: '@every 10s'
        '';
        description = mdDoc "Any other configuration options you want to add";
      };

    };
  };

  config = mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d '${cfg.stateDir}' - nobody nogroup - -"
    ];

    systemd.services.heartbeat = {
      description = "heartbeat log shipper";
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        mkdir -p "${cfg.stateDir}"/{data,logs}
      '';
      serviceConfig = {
        User = "nobody";
        AmbientCapabilities = "cap_net_raw";
        ExecStart = "${cfg.package}/bin/heartbeat -c \"${heartbeatYml}\" -path.data \"${cfg.stateDir}/data\" -path.logs \"${cfg.stateDir}/logs\"";
      };
    };
  };
}
