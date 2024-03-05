{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.xbanish;

in {
  options.services.xbanish = {

    enable = mkEnableOption (mdDoc "xbanish");

    arguments = mkOption {
      description = mdDoc "Arguments to pass to xbanish command";
      default = "";
      example = "-d -i shift";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.xbanish = {
      description = "xbanish hides the mouse pointer";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = ''
        ${pkgs.xbanish}/bin/xbanish ${cfg.arguments}
      '';
      serviceConfig.Restart = "always";
    };
  };
}
