{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.powerManagement.powertop;
in {
  ###### interface

  options.powerManagement.powertop.enable = mkEnableOption (mdDoc "powertop auto tuning on startup");

  ###### implementation

  config = mkIf (cfg.enable) {
    systemd.services = {
      powertop = {
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        description = "Powertop tunings";
        path = [ pkgs.kmod ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.powertop}/bin/powertop --auto-tune";
        };
      };
    };
  };
}
