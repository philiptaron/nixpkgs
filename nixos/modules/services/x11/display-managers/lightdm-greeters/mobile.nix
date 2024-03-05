{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkDefault
    mkEnableOption
    mkIf
    ;

  dmcfg = config.services.xserver.displayManager;
  ldmcfg = dmcfg.lightdm;
  cfg = ldmcfg.greeters.mobile;
in
{
  options = {
    services.xserver.displayManager.lightdm.greeters.mobile = {
      enable = mkEnableOption (mdDoc
        "lightdm-mobile-greeter as the lightdm greeter"
      );
    };
  };

  config = mkIf (ldmcfg.enable && cfg.enable) {
    services.xserver.displayManager.lightdm.greeters.gtk.enable = false;

    services.xserver.displayManager.lightdm.greeter = mkDefault {
      package = pkgs.lightdm-mobile-greeter.xgreeters;
      name = "lightdm-mobile-greeter";
    };
  };
}
