# neard service.
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{
  ###### interface
  options = {
    services.neard = {
      enable = mkEnableOption (mdDoc "neard, NFC daemon");
    };
  };


  ###### implementation
  config = mkIf config.services.neard.enable {
    environment.systemPackages = [ pkgs.neard ];

    services.dbus.packages = [ pkgs.neard ];

    systemd.packages = [ pkgs.neard ];
  };
}
