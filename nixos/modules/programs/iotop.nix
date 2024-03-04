{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.iotop;
in
{
  options = {
    programs.iotop.enable = mkEnableOption (mdDoc "iotop + setcap wrapper");
  };

  config = mkIf cfg.enable {
    security.wrappers.iotop = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin+p";
      source = "${pkgs.iotop}/bin/iotop";
    };
  };
}
