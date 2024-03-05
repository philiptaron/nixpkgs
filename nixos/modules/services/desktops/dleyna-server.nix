# dleyna-server service.
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;
in

{
  ###### interface
  options = {
    services.dleyna-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable dleyna-server service, a DBus service
          for handling DLNA servers.
        '';
      };
    };
  };


  ###### implementation
  config = mkIf config.services.dleyna-server.enable {
    environment.systemPackages = [ pkgs.dleyna-server ];

    services.dbus.packages = [ pkgs.dleyna-server ];
  };
}
