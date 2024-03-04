# Evince.

{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    mkRenamedOptionModule
    ;

  cfg = config.programs.evince;
in
{

  # Added 2019-08-09
  imports = [
    (mkRenamedOptionModule
      [ "services" "gnome3" "evince" "enable" ]
      [ "programs" "evince" "enable" ])
  ];

  ###### interface

  options = {

    programs.evince = {

      enable = mkEnableOption
        (mdDoc "Evince, the GNOME document viewer");

      package = mkPackageOption pkgs "evince" { };

    };

  };


  ###### implementation

  config = mkIf config.programs.evince.enable {

    environment.systemPackages = [ cfg.package ];

    services.dbus.packages = [ cfg.package ];

    systemd.packages = [ cfg.package ];

  };

}
