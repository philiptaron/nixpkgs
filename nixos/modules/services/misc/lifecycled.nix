{ config, pkgs, lib, ... }:

let
  inherit (lib)
    boolToString
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    optionalString
    types
    ;

  cfg = config.services.lifecycled;

  # TODO: Add the ability to extend this with an rfc 42-like interface.
  # In the meantime, one can modify the environment (as
  # long as it's not overriding anything from here) with
  # systemd.services.lifecycled.serviceConfig.Environment
  configFile = pkgs.writeText "lifecycled" ''
    LIFECYCLED_HANDLER=${cfg.handler}
    ${optionalString (cfg.cloudwatchGroup != null) "LIFECYCLED_CLOUDWATCH_GROUP=${cfg.cloudwatchGroup}"}
    ${optionalString (cfg.cloudwatchStream != null) "LIFECYCLED_CLOUDWATCH_STREAM=${cfg.cloudwatchStream}"}
    ${optionalString cfg.debug "LIFECYCLED_DEBUG=${boolToString cfg.debug}"}
    ${optionalString (cfg.instanceId != null) "LIFECYCLED_INSTANCE_ID=${cfg.instanceId}"}
    ${optionalString cfg.json "LIFECYCLED_JSON=${boolToString cfg.json}"}
    ${optionalString cfg.noSpot "LIFECYCLED_NO_SPOT=${boolToString cfg.noSpot}"}
    ${optionalString (cfg.snsTopic != null) "LIFECYCLED_SNS_TOPIC=${cfg.snsTopic}"}
    ${optionalString (cfg.awsRegion != null) "AWS_REGION=${cfg.awsRegion}"}
  '';
in
{
  meta.maintainers = with maintainers; [ cole-h grahamc ];

  options = {
    services.lifecycled = {
      enable = mkEnableOption (mdDoc "lifecycled");

      queueCleaner = {
        enable = mkEnableOption (mdDoc "lifecycled-queue-cleaner");

        frequency = mkOption {
          type = types.str;
          default = "hourly";
          description = mdDoc ''
            How often to trigger the queue cleaner.

            NOTE: This string should be a valid value for a systemd
            timer's `OnCalendar` configuration. See
            {manpage}`systemd.timer(5)`
            for more information.
          '';
        };

        parallel = mkOption {
          type = types.ints.unsigned;
          default = 20;
          description = mdDoc ''
            The number of parallel deletes to run.
          '';
        };
      };

      instanceId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          The instance ID to listen for events for.
        '';
      };

      snsTopic = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          The SNS topic that receives events.
        '';
      };

      noSpot = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Disable the spot termination listener.
        '';
      };

      handler = mkOption {
        type = types.path;
        description = mdDoc ''
          The script to invoke to handle events.
        '';
      };

      json = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable JSON logging.
        '';
      };

      cloudwatchGroup = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          Write logs to a specific Cloudwatch Logs group.
        '';
      };

      cloudwatchStream = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          Write logs to a specific Cloudwatch Logs stream. Defaults to the instance ID.
        '';
      };

      debug = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable debugging information.
        '';
      };

      # XXX: Can be removed if / when
      # https://github.com/buildkite/lifecycled/pull/91 is merged.
      awsRegion = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          The region used for accessing AWS services.
        '';
      };
    };
  };

  ### Implementation ###

  config = mkMerge [
    (mkIf cfg.enable {
      environment.etc."lifecycled".source = configFile;

      systemd.packages = [ pkgs.lifecycled ];
      systemd.services.lifecycled = {
        wantedBy = [ "network-online.target" ];
        restartTriggers = [ configFile ];
      };
    })

    (mkIf cfg.queueCleaner.enable {
      systemd.services.lifecycled-queue-cleaner = {
        description = "Lifecycle Daemon Queue Cleaner";
        environment = optionalAttrs (cfg.awsRegion != null) { AWS_REGION = cfg.awsRegion; };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.lifecycled}/bin/lifecycled-queue-cleaner -parallel ${toString cfg.queueCleaner.parallel}";
        };
      };

      systemd.timers.lifecycled-queue-cleaner = {
        description = "Lifecycle Daemon Queue Cleaner Timer";
        wantedBy = [ "timers.target" ];
        after = [ "network-online.target" ];
        timerConfig = {
          Unit = "lifecycled-queue-cleaner.service";
          OnCalendar = "${cfg.queueCleaner.frequency}";
        };
      };
    })
  ];
}
