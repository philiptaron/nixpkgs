{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.mtr;
in
{
  options = {
    programs.mtr = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to add mtr to the global environment and configure a
          setcap wrapper for it.
        '';
      };

      package = mkPackageOption pkgs "mtr" { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cfg.package ];

    security.wrappers.mtr-packet = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_raw+p";
      source = "${cfg.package}/bin/mtr-packet";
    };
  };
}
