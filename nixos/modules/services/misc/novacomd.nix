{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.novacomd;

in {
  options = {
    services.novacomd = {
      enable = mkEnableOption (mdDoc "Novacom service for connecting to WebOS devices");
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.webos.novacom ];

    systemd.services.novacomd = {
      description = "Novacom WebOS daemon";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.webos.novacomd}/sbin/novacomd";
      };
    };
  };

  meta.maintainers = with maintainers; [ dtzWill ];
}
