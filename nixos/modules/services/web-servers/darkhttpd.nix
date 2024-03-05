{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.services.darkhttpd;

  args = concatStringsSep " " ([
    cfg.rootDir
    "--port ${toString cfg.port}"
    "--addr ${cfg.address}"
  ] ++ cfg.extraArgs
    ++ optional cfg.hideServerId             "--no-server-id"
    ++ optional config.networking.enableIPv6 "--ipv6");

in {
  options.services.darkhttpd = with types; {
    enable = mkEnableOption (mdDoc "DarkHTTPd web server");

    port = mkOption {
      default = 80;
      type = types.port;
      description = mdDoc ''
        Port to listen on.
        Pass 0 to let the system choose any free port for you.
      '';
    };

    address = mkOption {
      default = "127.0.0.1";
      type = str;
      description = mdDoc ''
        Address to listen on.
        Pass `all` to listen on all interfaces.
      '';
    };

    rootDir = mkOption {
      type = path;
      description = mdDoc ''
        Path from which to serve files.
      '';
    };

    hideServerId = mkOption {
      type = bool;
      default = true;
      description = mdDoc ''
        Don't identify the server type in headers or directory listings.
      '';
    };

    extraArgs = mkOption {
      type = listOf str;
      default = [];
      description = mdDoc ''
        Additional configuration passed to the executable.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.darkhttpd = {
      description = "Dark HTTPd";
      wants = [ "network.target" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${pkgs.darkhttpd}/bin/darkhttpd ${args}";
        AmbientCapabilities = mkIf (cfg.port < 1024) [ "CAP_NET_BIND_SERVICE" ];
        Restart = "on-failure";
        RestartSec = "2s";
      };
    };
  };
}
