{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.services.monetdb;

in
{
  meta.maintainers = with maintainers; [ StillerHarpo primeos ];

  ###### interface
  options = {
    services.monetdb = {

      enable = mkEnableOption (mdDoc "the MonetDB database server");

      package = mkPackageOption pkgs "monetdb" { };

      user = mkOption {
        type = types.str;
        default = "monetdb";
        description = mdDoc "User account under which MonetDB runs.";
      };

      group = mkOption {
        type = types.str;
        default = "monetdb";
        description = mdDoc "Group under which MonetDB runs.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/monetdb";
        description = mdDoc "Data directory for the dbfarm.";
      };

      port = mkOption {
        type = types.ints.u16;
        default = 50000;
        description = mdDoc "Port to listen on.";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
        description = mdDoc "Address to listen on.";
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {

    users.users.monetdb = mkIf (cfg.user == "monetdb") {
      uid = config.ids.uids.monetdb;
      group = cfg.group;
      description = "MonetDB user";
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.monetdb = mkIf (cfg.group == "monetdb") {
      gid = config.ids.gids.monetdb;
      members = [ cfg.user ];
    };

    environment.systemPackages = [ cfg.package ];

    systemd.services.monetdb = {
      description = "MonetDB database server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ cfg.package ];
      unitConfig.RequiresMountsFor = "${cfg.dataDir}";
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/monetdbd start -n ${cfg.dataDir}";
        ExecStop = "${cfg.package}/bin/monetdbd stop ${cfg.dataDir}";
      };
      preStart = ''
        if [ ! -e ${cfg.dataDir}/.merovingian_properties ]; then
          # Create the dbfarm (as cfg.user)
          ${cfg.package}/bin/monetdbd create ${cfg.dataDir}
        fi

        # Update the properties
        ${cfg.package}/bin/monetdbd set port=${toString cfg.port} ${cfg.dataDir}
        ${cfg.package}/bin/monetdbd set listenaddr=${cfg.listenAddress} ${cfg.dataDir}
      '';
    };

  };
}
