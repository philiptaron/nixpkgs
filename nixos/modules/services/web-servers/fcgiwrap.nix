{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    optional
    optionalString
    types
    ;

  cfg = config.services.fcgiwrap;
in {

  options = {
    services.fcgiwrap = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to enable fcgiwrap, a server for running CGI applications over FastCGI.";
      };

      preforkProcesses = mkOption {
        type = types.int;
        default = 1;
        description = mdDoc "Number of processes to prefork.";
      };

      socketType = mkOption {
        type = types.enum [ "unix" "tcp" "tcp6" ];
        default = "unix";
        description = mdDoc "Socket type: 'unix', 'tcp' or 'tcp6'.";
      };

      socketAddress = mkOption {
        type = types.str;
        default = "/run/fcgiwrap.sock";
        example = "1.2.3.4:5678";
        description = mdDoc "Socket address. In case of a UNIX socket, this should be its filesystem path.";
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "User permissions for the socket.";
      };

      group = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "Group permissions for the socket.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.fcgiwrap = {
      after = [ "nss-user-lookup.target" ];
      wantedBy = optional (cfg.socketType != "unix") "multi-user.target";

      serviceConfig = {
        ExecStart = "${pkgs.fcgiwrap}/sbin/fcgiwrap -c ${builtins.toString cfg.preforkProcesses} ${
          optionalString (cfg.socketType != "unix") "-s ${cfg.socketType}:${cfg.socketAddress}"
        }";
      } // (if cfg.user != null && cfg.group != null then {
        User = cfg.user;
        Group = cfg.group;
      } else { } );
    };

    systemd.sockets = if (cfg.socketType == "unix") then {
      fcgiwrap = {
        wantedBy = [ "sockets.target" ];
        socketConfig.ListenStream = cfg.socketAddress;
      };
    } else { };
  };
}
