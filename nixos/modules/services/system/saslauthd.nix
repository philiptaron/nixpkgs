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

  cfg = config.services.saslauthd;

in

{

  ###### interface

  options = {

    services.saslauthd = {

      enable = mkEnableOption (mdDoc "saslauthd, the Cyrus SASL authentication daemon");

      package = mkPackageOption pkgs [ "cyrus_sasl" "bin" ] { };

      mechanism = mkOption {
        type = types.str;
        default = "pam";
        description = mdDoc "Auth mechanism to use";
      };

      config = mkOption {
        type = types.lines;
        default = "";
        description = mdDoc "Configuration to use for Cyrus SASL authentication daemon.";
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    systemd.services.saslauthd = {
      description = "Cyrus SASL authentication daemon";

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "@${cfg.package}/sbin/saslauthd saslauthd -a ${cfg.mechanism} -O ${pkgs.writeText "saslauthd.conf" cfg.config}";
        Type = "forking";
        PIDFile = "/run/saslauthd/saslauthd.pid";
        Restart = "always";
      };
    };
  };
}
