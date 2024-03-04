{ config, lib, pkgs, ... }:

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

  cfg = config.programs.streamdeck-ui;
in
{
  options.programs.streamdeck-ui = {
    enable = mkEnableOption (mdDoc "streamdeck-ui");

    autoStart = mkOption {
      default = true;
      type = types.bool;
      description = mdDoc "Whether streamdeck-ui should be started automatically.";
    };

    package = mkPackageOption pkgs "streamdeck-ui" {
      default = [ "streamdeck-ui" ];
    };

  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.package
      (mkIf cfg.autoStart (makeAutostartItem { name = "streamdeck-ui-noui"; package = cfg.package; }))
    ];

    services.udev.packages = [ cfg.package ];
  };

  meta.maintainers = with maintainers; [ majiir ];
}
