{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.lldpd;

in

{
  options.services.lldpd = {
    enable = mkEnableOption (mdDoc "Link Layer Discovery Protocol Daemon");

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "-c" "-k" "-I eth0" ];
      description = mdDoc "List of command line parameters for lldpd";
    };
  };

  config = mkIf cfg.enable {
    users.users._lldpd = {
      description = "lldpd user";
      group = "_lldpd";
      home = "/run/lldpd";
      isSystemUser = true;
    };
    users.groups._lldpd = {};

    environment.systemPackages = [ pkgs.lldpd ];
    systemd.packages = [ pkgs.lldpd ];

    systemd.services.lldpd = {
      wantedBy = [ "multi-user.target" ];
      environment.LLDPD_OPTIONS = concatStringsSep " " cfg.extraArgs;
    };
  };
}
