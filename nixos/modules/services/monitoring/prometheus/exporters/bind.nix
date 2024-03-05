{ config, lib, pkgs, options }:

let
  inherit (lib)
    collect
    concatStringsSep
    mdDoc
    mkOption
    types
    ;

  cfg = config.services.prometheus.exporters.bind;
in
{
  port = 9119;
  extraOpts = {
    bindURI = mkOption {
      type = types.str;
      default = "http://localhost:8053/";
      description = mdDoc ''
        HTTP XML API address of an Bind server.
      '';
    };
    bindTimeout = mkOption {
      type = types.str;
      default = "10s";
      description = mdDoc ''
        Timeout for trying to get stats from Bind.
      '';
    };
    bindVersion = mkOption {
      type = types.enum [ "xml.v2" "xml.v3" "auto" ];
      default = "auto";
      description = mdDoc ''
        BIND statistics version. Can be detected automatically.
      '';
    };
    bindGroups = mkOption {
      type = types.listOf (types.enum [ "server" "view" "tasks" ]);
      default = [ "server" "view" ];
      description = mdDoc ''
        List of statistics to collect. Available: [server, view, tasks]
      '';
    };
  };
  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-bind-exporter}/bin/bind_exporter \
          --web.listen-address ${cfg.listenAddress}:${toString cfg.port} \
          --bind.pid-file /var/run/named/named.pid \
          --bind.timeout ${toString cfg.bindTimeout} \
          --bind.stats-url ${cfg.bindURI} \
          --bind.stats-version ${cfg.bindVersion} \
          --bind.stats-groups ${concatStringsSep "," cfg.bindGroups} \
          ${concatStringsSep " \\\n  " cfg.extraFlags}
      '';
    };
  };
}
