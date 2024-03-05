{ config, lib, pkgs, ... }:

let
  inherit (lib)
    generators
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.create_ap;
  configFile = pkgs.writeText "create_ap.conf" (generators.toKeyValue { } cfg.settings);
in {
  options = {
    services.create_ap = {
      enable = mkEnableOption (mdDoc "setting up wifi hotspots using create_ap");
      settings = mkOption {
        type = with types; attrsOf (oneOf [ int bool str ]);
        default = {};
        description = mdDoc ''
          Configuration for `create_ap`.
          See [upstream example configuration](https://raw.githubusercontent.com/lakinduakash/linux-wifi-hotspot/master/src/scripts/create_ap.conf)
          for supported values.
        '';
        example = {
          INTERNET_IFACE = "eth0";
          WIFI_IFACE = "wlan0";
          SSID = "My Wifi Hotspot";
          PASSPHRASE = "12345678";
        };
      };
    };
  };

  config = mkIf cfg.enable {

    systemd = {
      services.create_ap = {
        wantedBy = [ "multi-user.target" ];
        description = "Create AP Service";
        after = [ "network.target" ];
        restartTriggers = [ configFile ];
        serviceConfig = {
          ExecStart = "${pkgs.linux-wifi-hotspot}/bin/create_ap --config ${configFile}";
          KillSignal = "SIGINT";
          Restart = "on-failure";
        };
      };
    };

  };

  meta.maintainers = with maintainers; [ onny ];

}
