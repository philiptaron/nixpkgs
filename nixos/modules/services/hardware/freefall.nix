{ config, lib, pkgs, utils, ... }:

let
  inherit (lib)
    listToAttrs
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    nameValuePair
    types
    ;

  cfg = config.services.freefall;

in {

  options.services.freefall = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to protect HP/Dell laptop hard drives (not SSDs) in free fall.
      '';
    };

    package = mkPackageOption pkgs "freefall" { };

    devices = mkOption {
      type = types.listOf types.str;
      default = [ "/dev/sda" ];
      description = mdDoc ''
        Device paths to all internal spinning hard drives.
      '';
    };

  };

  config = let

    mkService = dev:
      assert dev != "";
      let dev' = utils.escapeSystemdPath dev; in
      nameValuePair "freefall-${dev'}" {
        description = "Free-fall protection for ${dev}";
        after = [ "${dev'}.device" ];
        wantedBy = [ "${dev'}.device" ];
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/freefall ${dev}";
          Restart = "on-failure";
          Type = "forking";
        };
      };

  in mkIf cfg.enable {

    environment.systemPackages = [ cfg.package ];

    systemd.services = builtins.listToAttrs (map mkService cfg.devices);

  };

}
