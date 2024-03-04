{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.hardware.xone;
in
{
  options.hardware.xone = {
    enable = mkEnableOption (mdDoc "the xone driver for Xbox One and Xbobx Series X|S accessories");
  };

  config = mkIf cfg.enable {
    boot = {
      blacklistedKernelModules = [ "xpad" "mt76x2u" ];
      extraModulePackages = with config.boot.kernelPackages; [ xone ];
    };
    hardware.firmware = [ pkgs.xow_dongle-firmware ];
  };

  meta = {
    maintainers = with maintainers; [ rhysmdnz ];
  };
}
