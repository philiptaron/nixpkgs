{ config, lib, pkgs, ...}:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.hardware.bolt;
in
{
  options = {
    services.hardware.bolt = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable Bolt, a userspace daemon to enable
          security levels for Thunderbolt 3 on GNU/Linux.

          Bolt is used by GNOME 3 to handle Thunderbolt settings.
        '';
      };

      package = mkPackageOption pkgs "bolt" { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.udev.packages = [ cfg.package ];
    systemd.packages = [ cfg.package ];
  };
}
