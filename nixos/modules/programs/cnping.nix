{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.cnping;
in
{
  options = {
    programs.cnping = {
      enable = mkEnableOption (mdDoc "a setcap wrapper for cnping");
    };
  };

  config = mkIf cfg.enable {
    security.wrappers.cnping = {
      source = "${pkgs.cnping}/bin/cnping";
      capabilities = "cap_net_raw+ep";
    };
  };
}
