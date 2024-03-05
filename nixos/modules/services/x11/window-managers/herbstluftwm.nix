{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionalString
    singleton
    types
    ;

  cfg = config.services.xserver.windowManager.herbstluftwm;
in

{
  options = {
    services.xserver.windowManager.herbstluftwm = {
      enable = mkEnableOption (mdDoc "herbstluftwm");

      package = mkPackageOption pkgs "herbstluftwm" { };

      configFile = mkOption {
        default     = null;
        type        = with types; nullOr path;
        description = mdDoc ''
          Path to the herbstluftwm configuration file.  If left at the
          default value, $XDG_CONFIG_HOME/herbstluftwm/autostart will
          be used.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "herbstluftwm";
      start =
        let configFileClause = optionalString
            (cfg.configFile != null)
            ''-c "${cfg.configFile}"''
            ;
        in "${cfg.package}/bin/herbstluftwm ${configFileClause} &";
    };
    environment.systemPackages = [ cfg.package ];
  };
}
