{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.services.mjpg-streamer;

in {

  options = {

    services.mjpg-streamer = {

      enable = mkEnableOption (mdDoc "mjpg-streamer webcam streamer");

      inputPlugin = mkOption {
        type = types.str;
        default = "input_uvc.so";
        description = mdDoc ''
          Input plugin. See plugins documentation for more information.
        '';
      };

      outputPlugin = mkOption {
        type = types.str;
        default = "output_http.so -w @www@ -n -p 5050";
        description = mdDoc ''
          Output plugin. `@www@` is substituted for default mjpg-streamer www directory.
          See plugins documentation for more information.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "mjpg-streamer";
        description = mdDoc "mjpg-streamer user name.";
      };

      group = mkOption {
        type = types.str;
        default = "video";
        description = mdDoc "mjpg-streamer group name.";
      };

    };

  };

  config = mkIf cfg.enable {

    users.users = optionalAttrs (cfg.user == "mjpg-streamer") {
      mjpg-streamer = {
        uid = config.ids.uids.mjpg-streamer;
        group = cfg.group;
      };
    };

    systemd.services.mjpg-streamer = {
      description = "mjpg-streamer webcam streamer";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = 1;
      };

      script = ''
        IPLUGIN="${cfg.inputPlugin}"
        OPLUGIN="${cfg.outputPlugin}"
        OPLUGIN="''${OPLUGIN//@www@/${pkgs.mjpg-streamer}/share/mjpg-streamer/www}"
        exec ${pkgs.mjpg-streamer}/bin/mjpg_streamer -i "$IPLUGIN" -o "$OPLUGIN"
      '';
    };

  };

}
