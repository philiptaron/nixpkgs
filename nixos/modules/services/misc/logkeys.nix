{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.services.logkeys;
in
{
  options.services.logkeys = {
    enable = mkEnableOption (mdDoc "logkeys service");

    device = mkOption {
      description = mdDoc "Use the given device as keyboard input event device instead of /dev/input/eventX default.";
      default = null;
      type = types.nullOr types.str;
      example = "/dev/input/event15";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.logkeys = {
      description = "LogKeys Keylogger Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.logkeys}/bin/logkeys -s${optionalString (cfg.device != null) " -d ${cfg.device}"}";
        ExecStop = "${pkgs.logkeys}/bin/logkeys -k";
        Type = "forking";
      };
    };
  };
}
