{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.wavemon;
in
{
  options = {
    programs.wavemon = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to add wavemon to the global environment and configure a
          setcap wrapper for it.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wavemon ];
    security.wrappers.wavemon = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin+ep";
      source = "${pkgs.wavemon}/bin/wavemon";
    };
  };
}
