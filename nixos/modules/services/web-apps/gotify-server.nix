{ pkgs, lib, config, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.gotify;
in {
  options = {
    services.gotify = {
      enable = mkEnableOption (mdDoc "Gotify webserver");

      port = mkOption {
        type = types.port;
        description = mdDoc ''
          Port the server listens to.
        '';
      };

      stateDirectoryName = mkOption {
        type = types.str;
        default = "gotify-server";
        description = mdDoc ''
          The name of the directory below {file}`/var/lib` where
          gotify stores its runtime data.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.gotify-server = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Simple server for sending and receiving messages";

      environment = {
        GOTIFY_SERVER_PORT = toString cfg.port;
      };

      serviceConfig = {
        WorkingDirectory = "/var/lib/${cfg.stateDirectoryName}";
        StateDirectory = cfg.stateDirectoryName;
        Restart = "always";
        DynamicUser = "yes";
        ExecStart = "${pkgs.gotify-server}/bin/server";
      };
    };
  };
}
