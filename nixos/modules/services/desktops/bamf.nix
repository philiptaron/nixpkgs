# Bamf

{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    teams
    ;
in

{
  meta = {
    maintainers = teams.pantheon.members;
  };

  ###### interface

  options = {
    services.bamf = {
      enable = mkEnableOption (mdDoc "bamf");
    };
  };

  ###### implementation

  config = mkIf config.services.bamf.enable {
    services.dbus.packages = [ pkgs.bamf ];

    systemd.packages = [ pkgs.bamf ];
  };
}
