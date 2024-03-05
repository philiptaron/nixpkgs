{ config, lib, options, pkgs, ... }:

let
  inherit (lib)
    literalExpression
    mdDoc
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  name = "headphones";

  cfg = config.services.headphones;

  opt = options.services.headphones;

in

{

  ###### interface

  options = {
    services.headphones = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to enable the headphones server.";
      };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/${name}";
        description = mdDoc "Path where to store data files.";
      };
      configFile = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/config.ini";
        defaultText = literalExpression ''"''${config.${opt.dataDir}}/config.ini"'';
        description = mdDoc "Path to config file.";
      };
      host = mkOption {
        type = types.str;
        default = "localhost";
        description = mdDoc "Host to listen on.";
      };
      port = mkOption {
        type = types.ints.u16;
        default = 8181;
        description = mdDoc "Port to bind to.";
      };
      user = mkOption {
        type = types.str;
        default = name;
        description = mdDoc "User to run the service as";
      };
      group = mkOption {
        type = types.str;
        default = name;
        description = mdDoc "Group to run the service as";
      };
    };
  };


  ###### implementation

  config = mkIf cfg.enable {

    users.users = optionalAttrs (cfg.user == name) {
      ${name} = {
        uid = config.ids.uids.headphones;
        group = cfg.group;
        description = "headphones user";
        home = cfg.dataDir;
        createHome = true;
      };
    };

    users.groups = optionalAttrs (cfg.group == name) {
      ${name}.gid = config.ids.gids.headphones;
    };

    systemd.services.headphones = {
        description = "Headphones Server";
        wantedBy    = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${pkgs.headphones}/bin/headphones --datadir ${cfg.dataDir} --config ${cfg.configFile} --host ${cfg.host} --port ${toString cfg.port}";
        };
    };
  };
}
