# Tumbler

{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkRemovedOptionModule
    teams
    ;

  cfg = config.services.tumbler;

in

{

  imports = [
    (mkRemovedOptionModule
      [ "services" "tumbler" "package" ]
      "")
  ];

  meta = {
    maintainers = teams.pantheon.members;
  };

  ###### interface

  options = {

    services.tumbler = {

      enable = mkEnableOption (mdDoc "Tumbler, A D-Bus thumbnailer service");

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs.xfce; [
      tumbler
    ];

    services.dbus.packages = with pkgs.xfce; [
      tumbler
    ];

  };

}
