{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    teams
    ;

  cfg = config.programs.xfconf;
in
{
  meta = {
    maintainers = teams.xfce.members;
  };

  options = {
    programs.xfconf = {
      enable = mkEnableOption (mdDoc "Xfconf, the Xfce configuration storage system");
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.xfce.xfconf
    ];

    services.dbus.packages = [
      pkgs.xfce.xfconf
    ];
  };
}
