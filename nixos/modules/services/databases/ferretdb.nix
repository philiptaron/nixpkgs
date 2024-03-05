{ config, pkgs, lib, ... }:

let
  inherit (lib)
    literalExpression
    maintainers
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.ferretdb;
in
{

  meta.maintainers = with maintainers; [ julienmalka camillemndn ];

  options = {
    services.ferretdb = {
      enable = mkEnableOption "FerretDB, an Open Source MongoDB alternative";

      package = mkOption {
        type = types.package;
        example = literalExpression "pkgs.ferretdb";
        default = pkgs.ferretdb;
        defaultText = "pkgs.ferretdb";
        description = "FerretDB package to use.";
      };

      settings = mkOption {
        type =
          types.submodule { freeformType = with types; attrsOf str; };
        example = {
          FERRETDB_LOG_LEVEL = "warn";
          FERRETDB_MODE = "normal";
        };
        description = ''
          Additional configuration for FerretDB, see
          <https://docs.ferretdb.io/configuration/flags/>
          for supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable
    {

      services.ferretdb.settings = {
        FERRETDB_HANDLER = mkDefault "sqlite";
        FERRETDB_SQLITE_URL = mkDefault "file:/var/lib/ferretdb/";
      };

      systemd.services.ferretdb = {
        description = "FerretDB";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = cfg.settings;
        serviceConfig = {
          Type = "simple";
          StateDirectory = "ferretdb";
          WorkingDirectory = "/var/lib/ferretdb";
          ExecStart = "${cfg.package}/bin/ferretdb";
          Restart = "on-failure";
          ProtectHome = true;
          ProtectSystem = "strict";
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHostname = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          NoNewPrivileges = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RemoveIPC = true;
          PrivateMounts = true;
          DynamicUser = true;
        };
      };
    };
}

