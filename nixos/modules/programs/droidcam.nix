{ lib, pkgs, config, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{
  options.programs.droidcam = {
    enable = mkEnableOption (mdDoc "DroidCam client");
  };

  config = mkIf config.programs.droidcam.enable {
    environment.systemPackages = [ pkgs.droidcam ];

    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" "snd-aloop" ];
  };
}
