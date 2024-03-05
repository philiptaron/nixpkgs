{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    getBin
    maintainers
    mdDoc
    mkIf
    mkOption
    mkRemovedOptionModule
    types
    ;

  cfg = config.services.pykms;

  libDir = "/var/lib/pykms";

in
{
  meta.maintainers = with maintainers; [ peterhoeg ];

  imports = [
    (mkRemovedOptionModule [ "services" "pykms" "verbose" ] "Use services.pykms.logLevel instead")
  ];

  options = {
    services.pykms = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to enable the PyKMS service.";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = mdDoc "The IP address on which to listen.";
      };

      port = mkOption {
        type = types.port;
        default = 1688;
        description = mdDoc "The port on which to listen.";
      };

      openFirewallPort = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether the listening port should be opened automatically.";
      };

      memoryLimit = mkOption {
        type = types.str;
        default = "64M";
        description = mdDoc "How much memory to use at most.";
      };

      logLevel = mkOption {
        type = types.enum [ "CRITICAL" "ERROR" "WARNING" "INFO" "DEBUG" "MININFO" ];
        default = "INFO";
        description = mdDoc "How much to log";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = mdDoc "Additional arguments";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewallPort [ cfg.port ];

    systemd.services.pykms = {
      description = "Python KMS";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      # python programs with DynamicUser = true require HOME to be set
      environment.HOME = libDir;
      serviceConfig = with pkgs; {
        DynamicUser = true;
        StateDirectory = baseNameOf libDir;
        ExecStartPre = "${getBin pykms}/libexec/create_pykms_db.sh ${libDir}/clients.db";
        ExecStart = concatStringsSep " " ([
          "${getBin pykms}/bin/server"
          "--logfile=STDOUT"
          "--loglevel=${cfg.logLevel}"
          "--sqlite=${libDir}/clients.db"
        ] ++ cfg.extraArgs ++ [
          cfg.listenAddress
          (toString cfg.port)
        ]);
        ProtectHome = "tmpfs";
        WorkingDirectory = libDir;
        SyslogIdentifier = "pykms";
        Restart = "on-failure";
        MemoryMax = cfg.memoryLimit;
      };
    };
  };
}
