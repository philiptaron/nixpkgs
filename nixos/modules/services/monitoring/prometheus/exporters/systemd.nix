{ config, pkgs, lib, ... }:

let
  inherit (lib)
    concatStringsSep
    ;

  cfg = config.services.prometheus.exporters.systemd;

in {
  port = 9558;

  serviceOpts = {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-systemd-exporter}/bin/systemd_exporter \
          --web.listen-address ${cfg.listenAddress}:${toString cfg.port} ${concatStringsSep " " cfg.extraFlags}
      '';
      RestrictAddressFamilies = [
        # Need AF_UNIX to collect data
        "AF_UNIX"
      ];
    };
  };
}
