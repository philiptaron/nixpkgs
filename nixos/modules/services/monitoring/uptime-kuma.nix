{ config, pkgs, lib, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optional
    types
    ;

  cfg = config.services.uptime-kuma;
in
{

  meta.maintainers = [ maintainers.julienmalka ];

  options = {
    services.uptime-kuma = {
      enable = mkEnableOption (mdDoc "Uptime Kuma, this assumes a reverse proxy to be set");

      package = mkPackageOption pkgs "uptime-kuma" { };

      appriseSupport = mkEnableOption (mdDoc "apprise support for notifications");

      settings = mkOption {
        type = types.submodule { freeformType = with types; attrsOf str; };
        default = { };
        example = {
          PORT = "4000";
          NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
        };
        description = mdDoc ''
          Additional configuration for Uptime Kuma, see
          <https://github.com/louislam/uptime-kuma/wiki/Environment-Variables>
          for supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    services.uptime-kuma.settings = {
      DATA_DIR = "/var/lib/uptime-kuma/";
      NODE_ENV = mkDefault "production";
      HOST = mkDefault "127.0.0.1";
      PORT = mkDefault "3001";
    };

    systemd.services.uptime-kuma = {
      description = "Uptime Kuma";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = cfg.settings;
      path = with pkgs; [ unixtools.ping ] ++ optional cfg.appriseSupport apprise;
      serviceConfig = {
        Type = "simple";
        StateDirectory = "uptime-kuma";
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/uptime-kuma-server";
        Restart = "on-failure";
        ProtectHome = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        NoNewPrivileges = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };
    };
  };
}

