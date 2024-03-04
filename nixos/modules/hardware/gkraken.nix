{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.hardware.gkraken;
in
{
  options.hardware.gkraken = {
    enable = mkEnableOption (mdDoc "gkraken's udev rules for NZXT AIO liquid coolers");
  };

  config = mkIf cfg.enable {
    services.udev.packages = with pkgs; [
      gkraken
    ];
  };
}
