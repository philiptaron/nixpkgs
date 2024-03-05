{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{
  #
  # interface
  #
  options = {
    services.gdomap = {
      enable = mkEnableOption (mdDoc "GNUstep Distributed Objects name server");
   };
  };

  #
  # implementation
  #
  config = mkIf config.services.gdomap.enable {
    # NOTE: gdomap runs as root
    # TODO: extra user for gdomap?
    systemd.services.gdomap = {
      description = "gdomap server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path  = [ pkgs.gnustep.base ];
      serviceConfig.ExecStart = "${pkgs.gnustep.base}/bin/gdomap -f";
    };
  };
}
