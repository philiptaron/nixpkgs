{ lib, pkgs, config, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.programs.waybar;
in
{
  options.programs.waybar = {
    enable = mkEnableOption (mdDoc "waybar");
    package = mkPackageOption pkgs "waybar" { };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    systemd.user.services.waybar = {
      description = "Waybar as systemd service";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      script = "${cfg.package}/bin/waybar";
    };
  };

  meta.maintainers = [ maintainers.FlorianFranzen ];
}
