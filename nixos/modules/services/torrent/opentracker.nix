{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.opentracker;
in {
  options.services.opentracker = {
    enable = mkEnableOption (mdDoc "opentracker");

    package = mkPackageOption pkgs "opentracker" { };

    extraOptions = mkOption {
      type = types.separatedString " ";
      description = mdDoc ''
        Configuration Arguments for opentracker
        See https://erdgeist.org/arts/software/opentracker/ for all params
      '';
      default = "";
    };
  };

  config = mkIf cfg.enable {

    systemd.services.opentracker = {
      description = "opentracker server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/opentracker ${cfg.extraOptions}";
        PrivateTmp = true;
        WorkingDirectory = "/var/empty";
        # By default opentracker drops all privileges and runs in chroot after starting up as root.
      };
    };
  };
}

