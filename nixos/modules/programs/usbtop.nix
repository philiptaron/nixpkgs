{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.usbtop;
in
{
  options = {
    programs.usbtop.enable = mkEnableOption (mdDoc "usbtop and required kernel module");
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      usbtop
    ];

    boot.kernelModules = [
      "usbmon"
    ];
  };
}
