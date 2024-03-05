{ config, lib, pkgs, options }:

let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    mdDoc
    mkEnableOption
    mkOption
    optionalString
    types
    ;

  cfg = config.services.prometheus.exporters.collectd;
in
{
  port = 9103;
  extraOpts = {
    collectdBinary = {
      enable = mkEnableOption (mdDoc "collectd binary protocol receiver");

      authFile = mkOption {
        default = null;
        type = types.nullOr types.path;
        description = mdDoc "File mapping user names to pre-shared keys (passwords).";
      };

      port = mkOption {
        type = types.port;
        default = 25826;
        description = mdDoc "Network address on which to accept collectd binary network packets.";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = mdDoc ''
          Address to listen on for binary network packets.
          '';
      };

      securityLevel = mkOption {
        type = types.enum ["None" "Sign" "Encrypt"];
        default = "None";
        description = mdDoc ''
          Minimum required security level for accepted packets.
        '';
      };
    };

    logFormat = mkOption {
      type = types.enum [ "logfmt" "json" ];
      default = "logfmt";
      example = "json";
      description = mdDoc ''
        Set the log format.
      '';
    };

    logLevel = mkOption {
      type = types.enum ["debug" "info" "warn" "error" "fatal"];
      default = "info";
      description = mdDoc ''
        Only log messages with the given severity or above.
      '';
    };
  };
  serviceOpts = let
    collectSettingsArgs = optionalString (cfg.collectdBinary.enable) ''
      --collectd.listen-address ${cfg.collectdBinary.listenAddress}:${toString cfg.collectdBinary.port} \
      --collectd.security-level ${cfg.collectdBinary.securityLevel} \
    '';
  in {
    serviceConfig = {
      ExecStart = ''
        ${pkgs.prometheus-collectd-exporter}/bin/collectd_exporter \
          --log.format ${escapeShellArg cfg.logFormat} \
          --log.level ${cfg.logLevel} \
          --web.listen-address ${cfg.listenAddress}:${toString cfg.port} \
          ${collectSettingsArgs} \
          ${concatStringsSep " \\\n  " cfg.extraFlags}
      '';
    };
  };
}
