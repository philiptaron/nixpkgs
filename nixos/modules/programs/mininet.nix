# Global configuration for mininet
# kernel must have NETNS/VETH/SCHED
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.mininet;
in
{
  options.programs.mininet.enable = mkEnableOption (mdDoc "Mininet");

  config = mkIf cfg.enable {

    virtualisation.vswitch.enable = true;

    environment.systemPackages = [ pkgs.mininet ];
  };
}
