{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.arbtt;
in
{
  options = {
    services.arbtt = {
      enable = mkEnableOption (mdDoc "Arbtt statistics capture service");

      package = mkPackageOption pkgs [ "haskellPackages" "arbtt" ] { };

      logFile = mkOption {
        type = types.str;
        default = "%h/.arbtt/capture.log";
        example = "/home/username/.arbtt-capture.log";
        description = mdDoc ''
          The log file for captured samples.
        '';
      };

      sampleRate = mkOption {
        type = types.int;
        default = 60;
        example = 120;
        description = mdDoc ''
          The sampling interval in seconds.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.arbtt = {
      description = "arbtt statistics capture service";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/arbtt-capture --logfile=${cfg.logFile} --sample-rate=${toString cfg.sampleRate}";
        Restart = "always";
      };
    };
  };

  meta.maintainers = [ maintainers.michaelpj ];
}
