{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    meta
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    mkRenamedOptionModule
    optionalString
    types
    ;

  cfg = config.hardware.ckb-next;
in
{
  imports = [
    (mkRenamedOptionModule [ "hardware" "ckb" "enable" ] [ "hardware" "ckb-next" "enable" ])
    (mkRenamedOptionModule [ "hardware" "ckb" "package" ] [ "hardware" "ckb-next" "package" ])
  ];

  options.hardware.ckb-next = {
    enable = mkEnableOption (mdDoc "the Corsair keyboard/mouse driver");

    gid = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 100;
      description = mdDoc ''
        Limit access to the ckb daemon to a particular group.
      '';
    };

    package = mkPackageOption pkgs "ckb-next" { };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.ckb-next = {
      description = "Corsair Keyboards and Mice Daemon";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ckb-next-daemon ${optionalString (cfg.gid != null) "--gid=${builtins.toString cfg.gid}"}";
        Restart = "on-failure";
      };
    };
  };
}
