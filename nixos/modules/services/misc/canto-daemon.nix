{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.services.canto-daemon;
in
{

##### interface

  options = {

    services.canto-daemon = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to enable the canto RSS daemon.";
      };
    };

  };

##### implementation

  config = mkIf cfg.enable {

    systemd.user.services.canto-daemon = {
      description = "Canto RSS Daemon";
      after = [ "network.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig.ExecStart = "${pkgs.canto-daemon}/bin/canto-daemon";
    };
  };

}
