{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.services.clipcat;
in
{
  options.services.clipcat = {
    enable = mkEnableOption (mdDoc "Clipcat clipboard daemon");

    package = mkPackageOption pkgs "clipcat" { };
  };

  config = mkIf cfg.enable {
    systemd.user.services.clipcat = {
      enable      = true;
      description = "clipcat daemon";
      wantedBy = [ "graphical-session.target" ];
      after    = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${cfg.package}/bin/clipcatd --no-daemon";
    };

    environment.systemPackages = [ cfg.package ];
  };
}
