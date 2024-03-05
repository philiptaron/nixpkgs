{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.phylactery;
in {
  options.services.phylactery = {
    enable = mkEnableOption (mdDoc "Phylactery server");

    host = mkOption {
      type = types.str;
      default = "localhost";
      description = mdDoc "Listen host for Phylactery";
    };

    port = mkOption {
      type = types.port;
      description = mdDoc "Listen port for Phylactery";
    };

    library = mkOption {
      type = types.path;
      description = mdDoc "Path to CBZ library";
    };

    package = mkPackageOption pkgs "phylactery" { };
  };

  config = mkIf cfg.enable {
    systemd.services.phylactery = {
      environment = {
        PHYLACTERY_ADDRESS = "${cfg.host}:${toString cfg.port}";
        PHYLACTERY_LIBRARY = "${cfg.library}";
      };

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ConditionPathExists = cfg.library;
        DynamicUser = true;
        ExecStart = "${cfg.package}/bin/phylactery";
      };
    };
  };

  meta.maintainers = with maintainers; [ McSinyx ];
}
