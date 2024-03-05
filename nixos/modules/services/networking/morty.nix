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

  cfg = config.services.morty;

in

{

  ###### interface

  options = {

    services.morty = {

      enable = mkEnableOption
        (mdDoc "Morty proxy server. See https://github.com/asciimoo/morty");

      ipv6 = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc "Allow IPv6 HTTP requests?";
      };

      key = mkOption {
        type = types.str;
        default = "";
        description = mdDoc ''
          HMAC url validation key (hexadecimal encoded).
          Leave blank to disable. Without validation key, anyone can
          submit proxy requests. Leave blank to disable.
          Generate with `printf %s somevalue | openssl dgst -sha1 -hmac somekey`
        '';
      };

      timeout = mkOption {
        type = types.int;
        default = 2;
        description = mdDoc "Request timeout in seconds.";
      };

      package = mkPackageOption pkgs "morty" { };

      port = mkOption {
        type = types.port;
        default = 3000;
        description = mdDoc "Listing port";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = mdDoc "The address on which the service listens";
      };

    };

  };

  ###### Service definition

  config = mkIf config.services.morty.enable {

    users.users.morty =
      { description = "Morty user";
        createHome = true;
        home = "/var/lib/morty";
        isSystemUser = true;
        group = "morty";
      };
    users.groups.morty = {};

    systemd.services.morty =
      {
        description = "Morty sanitizing proxy server.";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "morty";
          ExecStart = ''${cfg.package}/bin/morty              \
            -listen ${cfg.listenAddress}:${toString cfg.port} \
            ${optionalString cfg.ipv6 "-ipv6"}                \
            ${optionalString (cfg.key != "") "-key " + cfg.key} \
          '';
        };
      };
    environment.systemPackages = [ cfg.package ];

  };
}
