{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.sonarr;
in
{
  options = {
    services.sonarr = {
      enable = mkEnableOption (mdDoc "Sonarr");

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/sonarr/.config/NzbDrone";
        description = mdDoc "The directory where Sonarr stores its data files.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Open ports in the firewall for the Sonarr web interface
        '';
      };

      user = mkOption {
        type = types.str;
        default = "sonarr";
        description = mdDoc "User account under which Sonaar runs.";
      };

      group = mkOption {
        type = types.str;
        default = "sonarr";
        description = mdDoc "Group under which Sonaar runs.";
      };

      package = mkPackageOption pkgs "sonarr" { };
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.sonarr = {
      description = "Sonarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/NzbDrone -nobrowser -data='${cfg.dataDir}'";
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 8989 ];
    };

    users.users = mkIf (cfg.user == "sonarr") {
      sonarr = {
        group = cfg.group;
        home = cfg.dataDir;
        uid = config.ids.uids.sonarr;
      };
    };

    users.groups = mkIf (cfg.group == "sonarr") {
      sonarr.gid = config.ids.gids.sonarr;
    };
  };
}
