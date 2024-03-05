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

  cfg = config.services.jackett;

in
{
  options = {
    services.jackett = {
      enable = mkEnableOption (mdDoc "Jackett");

      dataDir = mkOption {
        type = types.str;
        default = "/var/lib/jackett/.config/Jackett";
        description = mdDoc "The directory where Jackett stores its data files.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Open ports in the firewall for the Jackett web interface.";
      };

      user = mkOption {
        type = types.str;
        default = "jackett";
        description = mdDoc "User account under which Jackett runs.";
      };

      group = mkOption {
        type = types.str;
        default = "jackett";
        description = mdDoc "Group under which Jackett runs.";
      };

      package = mkPackageOption pkgs "jackett" { };
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.jackett = {
      description = "Jackett";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/Jackett --NoUpdates --DataFolder '${cfg.dataDir}'";
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 9117 ];
    };

    users.users = mkIf (cfg.user == "jackett") {
      jackett = {
        group = cfg.group;
        home = cfg.dataDir;
        uid = config.ids.uids.jackett;
      };
    };

    users.groups = mkIf (cfg.group == "jackett") {
      jackett.gid = config.ids.gids.jackett;
    };
  };
}
