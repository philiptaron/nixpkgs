{ config, lib, pkgs, options }:

let
  inherit (lib)
    concatStringsSep
    literalExpression
    mdDoc
    mkOption
    optionalString
    types
    ;

  cfg = config.services.prometheus.exporters.flow;
in {
  port = 9590;
  extraOpts = {
    brokers = mkOption {
      type = types.listOf types.str;
      example = literalExpression ''[ "kafka.example.org:19092" ]'';
      description = mdDoc "List of Kafka brokers to connect to.";
    };

    asn = mkOption {
      type = types.ints.positive;
      example = 65542;
      description = mdDoc "The ASN being monitored.";
    };

    partitions = mkOption {
      type = types.listOf types.int;
      default = [];
      description = mdDoc ''
        The number of the partitions to consume, none means all.
      '';
    };

    topic = mkOption {
      type = types.str;
      example = "pmacct.acct";
      description = mdDoc "The Kafka topic to consume from.";
    };
  };

  serviceOpts = {
    serviceConfig = {
      DynamicUser = true;
      ExecStart = ''
        ${pkgs.prometheus-flow-exporter}/bin/flow-exporter \
          -asn ${toString cfg.asn} \
          -topic ${cfg.topic} \
          -brokers ${concatStringsSep "," cfg.brokers} \
          ${optionalString (cfg.partitions != []) "-partitions ${concatStringsSep "," cfg.partitions}"} \
          -addr ${cfg.listenAddress}:${toString cfg.port} ${concatStringsSep " " cfg.extraFlags}
      '';
    };
  };
}
