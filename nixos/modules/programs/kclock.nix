{ lib, pkgs, config, ... }:
let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.kclock;
  kclockPkg = pkgs.libsForQt5.kclock;
in
{
  options.programs.kclock = { enable = mkEnableOption (mdDoc "KClock"); };

  config = mkIf cfg.enable {
    services.dbus.packages = [ kclockPkg ];
    environment.systemPackages = [ kclockPkg ];
  };
}
