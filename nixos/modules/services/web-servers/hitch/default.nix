{ config, lib, pkgs, ...}:

let
  inherit (lib)
    concatMapStrings
    concatStringsSep
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionalString
    toList
    types
    ;

  cfg = config.services.hitch;

  ocspDir = optionalString cfg.ocsp-stapling.enabled "/var/cache/hitch/ocsp";

  hitchConfig = with lib; pkgs.writeText "hitch.conf" (concatStringsSep "\n" [
    ("backend = \"${cfg.backend}\"")
    (concatMapStrings (s: "frontend = \"${s}\"\n") cfg.frontend)
    (concatMapStrings (s: "pem-file = \"${s}\"\n") cfg.pem-files)
    ("ciphers = \"${cfg.ciphers}\"")
    ("ocsp-dir = \"${ocspDir}\"")
    "user = \"${cfg.user}\""
    "group = \"${cfg.group}\""
    cfg.extraConfig
  ]);
in
{
  options = {
    services.hitch = {
      enable = mkEnableOption (mdDoc "Hitch Server");

      backend = mkOption {
        type = types.str;
        description = mdDoc ''
          The host and port Hitch connects to when receiving
          a connection in the form [HOST]:PORT
        '';
      };

      ciphers = mkOption {
        type = types.str;
        default = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
        description = mdDoc "The list of ciphers to use";
      };

      frontend = mkOption {
        type = types.either types.str (types.listOf types.str);
        default = "[127.0.0.1]:443";
        description = mdDoc ''
          The port and interface of the listen endpoint in the
          form [HOST]:PORT[+CERT].
        '';
        apply = toList;
      };

      pem-files = mkOption {
        type = types.listOf types.path;
        default = [];
        description = mdDoc "PEM files to use";
      };

      ocsp-stapling = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = mdDoc "Whether to enable OCSP Stapling";
        };
      };

      user = mkOption {
        type = types.str;
        default = "hitch";
        description = mdDoc "The user to run as";
      };

      group = mkOption {
        type = types.str;
        default = "hitch";
        description = mdDoc "The group to run as";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = mdDoc "Additional configuration lines";
      };
    };

  };

  config = mkIf cfg.enable {

    systemd.services.hitch = {
      description = "Hitch";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      preStart = ''
        ${pkgs.hitch}/sbin/hitch -t --config ${hitchConfig}
      '' + (optionalString cfg.ocsp-stapling.enabled ''
        mkdir -p ${ocspDir}
        chown -R hitch:hitch ${ocspDir}
      '');
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.hitch}/sbin/hitch --daemon --config ${hitchConfig}";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "5s";
        LimitNOFILE = 131072;
      };
    };

    environment.systemPackages = [ pkgs.hitch ];

    users.users.hitch = {
      group = "hitch";
      isSystemUser = true;
    };
    users.groups.hitch = {};
  };
}
