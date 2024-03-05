{ config, lib, pkgs, options }:

let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    literalExpression
    mdDoc
    mkDefault
    mkOption
    optional
    types
    ;

  cfg = config.services.prometheus.exporters.varnish;
in
{
  port = 9131;
  extraOpts = {
    noExit = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Do not exit server on Varnish scrape errors.
      '';
    };
    withGoMetrics = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Export go runtime and http handler metrics.
      '';
    };
    verbose = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enable verbose logging.
      '';
    };
    raw = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Enable raw stdout logging without timestamps.
      '';
    };
    varnishStatPath = mkOption {
      type = types.str;
      default = "varnishstat";
      description = mdDoc ''
        Path to varnishstat.
      '';
    };
    instance = mkOption {
      type = types.nullOr types.str;
      default = config.services.varnish.stateDir;
      defaultText = literalExpression "config.services.varnish.stateDir";
      description = mdDoc ''
        varnishstat -n value.
      '';
    };
    healthPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc ''
        Path under which to expose healthcheck. Disabled unless configured.
      '';
    };
    telemetryPath = mkOption {
      type = types.str;
      default = "/metrics";
      description = mdDoc ''
        Path under which to expose metrics.
      '';
    };
  };
  serviceOpts = {
    path = [ config.services.varnish.package ];
    serviceConfig = {
      RestartSec = mkDefault 1;
      DynamicUser = false;
      ExecStart = ''
        ${pkgs.prometheus-varnish-exporter}/bin/prometheus_varnish_exporter \
          --web.listen-address ${cfg.listenAddress}:${toString cfg.port} \
          --web.telemetry-path ${cfg.telemetryPath} \
          --varnishstat-path ${escapeShellArg cfg.varnishStatPath} \
          ${concatStringsSep " \\\n  " (cfg.extraFlags
            ++ optional (cfg.healthPath != null) "--web.health-path ${cfg.healthPath}"
            ++ optional (cfg.instance != null) "-n ${escapeShellArg cfg.instance}"
            ++ optional cfg.noExit "--no-exit"
            ++ optional cfg.withGoMetrics "--with-go-metrics"
            ++ optional cfg.verbose "--verbose"
            ++ optional cfg.raw "--raw")}
      '';
    };
  };
}
