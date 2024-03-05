{ config, lib, pkgs, options }:

let
  inherit (lib)
    concatStringsSep
    ;

  cfg = config.services.prometheus.exporters.domain;
in
{
  port = 9222;
  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-domain-exporter}/bin/domain_exporter \
          --bind ${cfg.listenAddress}:${toString cfg.port} \
          ${concatStringsSep " \\\n  " cfg.extraFlags}
      '';
    };
  };
}
