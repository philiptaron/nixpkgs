{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkIf
    mkOption
    types
    ;
in

{
  meta.maintainers = with maintainers; [ grahamc ];
  options = {

    hardware.mcelog = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable the Machine Check Exception logger.
        '';
      };
    };

  };

  config = mkIf config.hardware.mcelog.enable {
    systemd = {
      packages = [ pkgs.mcelog ];

      services.mcelog = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ProtectHome = true;
          PrivateNetwork = true;
          PrivateTmp = true;
        };
      };
    };
  };
}
