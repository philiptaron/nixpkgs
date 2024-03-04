# File Roller.

{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    mkRenamedOptionModule
    ;

  cfg = config.programs.file-roller;
in
{

  # Added 2019-08-09
  imports = [
    (mkRenamedOptionModule
      [ "services" "gnome3" "file-roller" "enable" ]
      [ "programs" "file-roller" "enable" ])
  ];

  ###### interface

  options = {

    programs.file-roller = {

      enable = mkEnableOption (mdDoc "File Roller, an archive manager for GNOME");

      package = mkPackageOption pkgs [ "gnome" "file-roller" ] { };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    environment.systemPackages = [ cfg.package ];

    services.dbus.packages = [ cfg.package ];

  };

}
