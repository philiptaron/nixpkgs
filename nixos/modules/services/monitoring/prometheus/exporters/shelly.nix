{ config, lib, pkgs, options }:

let
  inherit (lib)
    mdDoc
    mkOption
    types
    ;

  cfg = config.services.prometheus.exporters.shelly;
in
{
  port = 9784;
  extraOpts = {
    metrics-file = mkOption {
      type = types.path;
      description = mdDoc ''
        Path to the JSON file with the metric definitions
      '';
    };
  };
  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-shelly-exporter}/bin/shelly_exporter \
          -metrics-file ${cfg.metrics-file} \
          -listen-address ${cfg.listenAddress}:${toString cfg.port}
      '';
    };
  };
}
