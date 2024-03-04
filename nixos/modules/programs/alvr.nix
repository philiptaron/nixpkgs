{ config, pkgs, lib, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.alvr;
in
{
  options = {
    programs.alvr = {
      enable = mkEnableOption (mdDoc "ALVR, the VR desktop streamer");

      package = mkPackageOption pkgs "alvr" { };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to open the default ports in the firewall for the ALVR server.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 9943 9944 ];
      allowedUDPPorts = [ 9943 9944 ];
    };
  };

  meta.maintainers = with maintainers; [ passivelemon ];
}
