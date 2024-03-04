{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mkIf
    ;
in
{
  config = mkIf (config.i18n.inputMethod.enabled == "nabi") {
    i18n.inputMethod.package = pkgs.nabi;

    environment.variables = {
      GTK_IM_MODULE = "nabi";
      QT_IM_MODULE  = "nabi";
      XMODIFIERS    = "@im=nabi";
    };

    services.xserver.displayManager.sessionCommands = "${pkgs.nabi}/bin/nabi &";
  };
}
