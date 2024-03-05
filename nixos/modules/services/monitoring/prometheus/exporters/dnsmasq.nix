{ config, lib, pkgs, options }:

let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    mdDoc
    mkOption
    types
    ;

  cfg = config.services.prometheus.exporters.dnsmasq;
in
{
  port = 9153;
  extraOpts = {
    dnsmasqListenAddress = mkOption {
      type = types.str;
      default = "localhost:53";
      description = mdDoc ''
        Address on which dnsmasq listens.
      '';
    };
    leasesPath = mkOption {
      type = types.path;
      default = "/var/lib/misc/dnsmasq.leases";
      example = "/var/lib/dnsmasq/dnsmasq.leases";
      description = mdDoc ''
        Path to the `dnsmasq.leases` file.
      '';
    };
  };
  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-dnsmasq-exporter}/bin/dnsmasq_exporter \
          --listen ${cfg.listenAddress}:${toString cfg.port} \
          --dnsmasq ${cfg.dnsmasqListenAddress} \
          --leases_path ${escapeShellArg cfg.leasesPath} \
          ${concatStringsSep " \\\n  " cfg.extraFlags}
      '';
    };
  };
}
