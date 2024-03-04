{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.traceroute;
in
{
  options = {
    programs.traceroute = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to configure a setcap wrapper for traceroute.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    security.wrappers.traceroute = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_raw+p";
      source = "${pkgs.traceroute}/bin/traceroute";
    };
  };
}
