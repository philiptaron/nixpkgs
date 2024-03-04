{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.calls;
in {
  options = {
    programs.calls = {
      enable = mkEnableOption (mdDoc ''
        GNOME calls: a phone dialer and call handler
      '');
    };
  };

  config = mkIf cfg.enable {
    programs.dconf.enable = true;

    environment.systemPackages = [
      pkgs.calls
    ];

    services.dbus.packages = [
      pkgs.callaudiod
    ];
  };
}
