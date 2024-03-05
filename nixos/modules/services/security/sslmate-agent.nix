{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.sslmate-agent;

in {
  meta.maintainers = with maintainers; [ wolfangaukang ];

  options = {
    services.sslmate-agent = {
      enable = mkEnableOption (mdDoc "sslmate-agent, a daemon for managing SSL/TLS certificates on a server");
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ sslmate-agent ];

    systemd = {
      packages = [ pkgs.sslmate-agent ];
      services.sslmate-agent = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ConfigurationDirectory = "sslmate-agent";
          LogsDirectory = "sslmate-agent";
          StateDirectory = "sslmate-agent";
        };
      };
    };
  };
}
