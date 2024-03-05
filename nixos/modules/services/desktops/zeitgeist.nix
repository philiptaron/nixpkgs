# Zeitgeist

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
    services.zeitgeist = {
      enable = mkEnableOption (mdDoc "zeitgeist");
    };
  };

  ###### implementation

  config = mkIf config.services.zeitgeist.enable {

    environment.systemPackages = [ pkgs.zeitgeist ];

    services.dbus.packages = [ pkgs.zeitgeist ];

    systemd.packages = [ pkgs.zeitgeist ];
  };
}
