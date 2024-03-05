{ config, lib, pkgs, ... }:
let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.usbrelayd;
in
{
  options.services.usbrelayd = {
    enable = mkEnableOption (mdDoc "USB Relay MQTT daemon");

    broker = mkOption {
      type = types.str;
      description = mdDoc "Hostname or IP address of your MQTT Broker.";
      default = "127.0.0.1";
      example = [
        "mqtt"
        "192.168.1.1"
      ];
    };

    clientName = mkOption {
      type = types.str;
      description = mdDoc "Name, your client connects as.";
      default = "MyUSBRelay";
    };
  };

  config = mkIf cfg.enable {

    environment.etc."usbrelayd.conf".text = ''
      [MQTT]
      BROKER = ${cfg.broker}
      CLIENTNAME = ${cfg.clientName}
    '';

    services.udev.packages = [ pkgs.usbrelayd ];
    systemd.packages = [ pkgs.usbrelayd ];
    users.groups.usbrelay = { };
  };

  meta = {
    maintainers = with maintainers; [ wentasah ];
  };
}
