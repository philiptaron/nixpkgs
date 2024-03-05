{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionalString
    types
    ;

  cfg = config.services.thermald;
in
{
  ###### interface
  options = {
    services.thermald = {
      enable = mkEnableOption (mdDoc "thermald, the temperature management daemon");

      debug = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable debug logging.
        '';
      };

     ignoreCpuidCheck = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to ignore the cpuid check to allow running on unsupported platforms";
      };

      configFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = mdDoc "the thermald manual configuration file.";
      };

      package = mkPackageOption pkgs "thermald" { };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.dbus.packages = [ cfg.package ];

    systemd.services.thermald = {
      description = "Thermal Daemon Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        PrivateNetwork = true;
        ExecStart = ''
          ${cfg.package}/sbin/thermald \
            --no-daemon \
            ${optionalString cfg.debug "--loglevel=debug"} \
            ${optionalString cfg.ignoreCpuidCheck "--ignore-cpuid-check"} \
            ${optionalString (cfg.configFile != null) "--config-file ${cfg.configFile}"} \
            --dbus-enable \
            --adaptive
        '';
      };
    };
  };
}
