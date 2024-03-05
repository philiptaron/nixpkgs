{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalString
    types
    ;

  cfg = config.services.freeradius;

  freeradiusService = cfg:
  {
    description = "FreeRadius server";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    wants = ["network.target"];
    preStart = ''
      ${pkgs.freeradius}/bin/radiusd -C -d ${cfg.configDir} -l stdout
    '';

    serviceConfig = {
        ExecStart = "${pkgs.freeradius}/bin/radiusd -f -d ${cfg.configDir} -l stdout" +
                    optionalString cfg.debug " -xx";
        ExecReload = [
          "${pkgs.freeradius}/bin/radiusd -C -d ${cfg.configDir} -l stdout"
          "${pkgs.coreutils}/bin/kill -HUP $MAINPID"
        ];
        User = "radius";
        ProtectSystem = "full";
        ProtectHome = "on";
        Restart = "on-failure";
        RestartSec = 2;
        LogsDirectory = "radius";
    };
  };

  freeradiusConfig = {
    enable = mkEnableOption (mdDoc "the freeradius server");

    configDir = mkOption {
      type = types.path;
      default = "/etc/raddb";
      description = mdDoc ''
        The path of the freeradius server configuration directory.
      '';
    };

    debug = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to enable debug logging for freeradius (-xx
        option). This should not be left on, since it includes
        sensitive data such as passwords in the logs.
      '';
    };

  };

in

{

  ###### interface

  options = {
    services.freeradius = freeradiusConfig;
  };


  ###### implementation

  config = mkIf (cfg.enable) {

    users = {
      users.radius = {
        /*uid = config.ids.uids.radius;*/
        description = "Radius daemon user";
        isSystemUser = true;
      };
    };

    systemd.services.freeradius = freeradiusService cfg;
    warnings = optional cfg.debug "Freeradius debug logging is enabled. This will log passwords in plaintext to the journal!";

  };

}
