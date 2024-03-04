{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionals
    types
    ;

  cfg  = config.programs.ausweisapp;
in
{
  options.programs.ausweisapp = {
    enable = mkEnableOption (mdDoc "AusweisApp");

    openFirewall = mkOption {
      description = mdDoc ''
        Whether to open the required firewall ports for the Smartphone as Card Reader (SaC) functionality of AusweisApp.
      '';
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ ausweisapp ];
    networking.firewall.allowedUDPPorts = optionals cfg.openFirewall [ 24727 ];
  };
}
