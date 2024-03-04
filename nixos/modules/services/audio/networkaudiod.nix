{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  name = "networkaudiod";
  cfg = config.services.networkaudiod;
in
{
  options = {
    services.networkaudiod = {
      enable = mkEnableOption (mdDoc "Networkaudiod (NAA)");
    };
  };

  config = mkIf cfg.enable {
    systemd.packages = [ pkgs.networkaudiod ];
    systemd.services.networkaudiod.wantedBy = [ "multi-user.target" ];
  };
}
