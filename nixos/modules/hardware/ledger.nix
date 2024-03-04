{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.hardware.ledger;
in
{
  options.hardware.ledger.enable = mkEnableOption (mdDoc "udev rules for Ledger devices");

  config = mkIf cfg.enable {
    services.udev.packages = [ pkgs.ledger-udev-rules ];
  };
}
