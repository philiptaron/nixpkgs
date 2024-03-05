{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.services.irqbalance;

in
{
  options.services.irqbalance.enable = mkEnableOption (mdDoc "irqbalance daemon");

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.irqbalance ];

    systemd.services.irqbalance.wantedBy = ["multi-user.target"];

    systemd.packages = [ pkgs.irqbalance ];

  };

}
