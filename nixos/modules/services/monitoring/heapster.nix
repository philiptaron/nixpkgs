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

  cfg = config.services.heapster;
in
{
  options.services.heapster = {
    enable = mkEnableOption (mdDoc "Heapster monitoring");

    source = mkOption {
      description = mdDoc "Heapster metric source";
      example = "kubernetes:https://kubernetes.default";
      type = types.str;
    };

    sink = mkOption {
      description = mdDoc "Heapster metic sink";
      example = "influxdb:http://localhost:8086";
      type = types.str;
    };

    extraOpts = mkOption {
      description = mdDoc "Heapster extra options";
      default = "";
      type = types.separatedString " ";
    };

    package = mkPackageOption pkgs "heapster" { };
  };

  config = mkIf cfg.enable {
    systemd.services.heapster = {
      wantedBy = ["multi-user.target"];
      after = ["cadvisor.service" "kube-apiserver.service"];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/heapster --source=${cfg.source} --sink=${cfg.sink} ${cfg.extraOpts}";
        User = "heapster";
      };
    };

    users.users.heapster = {
      isSystemUser = true;
      group = "heapster";
      description = "Heapster user";
    };
    users.groups.heapster = {};
  };
}
