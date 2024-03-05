{ config, lib, pkgs, ... }:

let
  inherit (lib)
    escapeShellArgs
    getBin
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.coredns;
  configFile = pkgs.writeText "Corefile" cfg.config;
in {
  options.services.coredns = {
    enable = mkEnableOption (mdDoc "Coredns dns server");

    config = mkOption {
      default = "";
      example = ''
        . {
          whoami
        }
      '';
      type = types.lines;
      description = mdDoc ''
        Verbatim Corefile to use.
        See <https://coredns.io/manual/toc/#configuration> for details.
      '';
    };

    package = mkPackageOption pkgs "coredns" { };

    extraArgs = mkOption {
      default = [];
      example = [ "-dns.port=53" ];
      type = types.listOf types.str;
      description = mdDoc "Extra arguments to pass to coredns.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.coredns = {
      description = "Coredns dns server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        PermissionsStartOnly = true;
        LimitNPROC = 512;
        LimitNOFILE = 1048576;
        CapabilityBoundingSet = "cap_net_bind_service";
        AmbientCapabilities = "cap_net_bind_service";
        NoNewPrivileges = true;
        DynamicUser = true;
        ExecStart = "${getBin cfg.package}/bin/coredns -conf=${configFile} ${escapeShellArgs cfg.extraArgs}";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
        Restart = "on-failure";
      };
    };
  };
}
