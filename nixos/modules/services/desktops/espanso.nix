{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.espanso;
in
{
  meta = { maintainers = with maintainers; [ numkem ]; };

  options = {
    services.espanso = { enable = mkEnableOption (mdDoc "Espanso"); };
  };

  config = mkIf cfg.enable {
    systemd.user.services.espanso = {
      description = "Espanso daemon";
      serviceConfig = {
        ExecStart = "${pkgs.espanso}/bin/espanso daemon";
        Restart = "on-failure";
      };
      wantedBy = [ "default.target" ];
    };

    environment.systemPackages = [ pkgs.espanso ];
  };
}
