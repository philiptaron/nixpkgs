{ config, lib, pkgs, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{
  meta.maintainers = pkgs.hamster.meta.maintainers;

  options.programs.hamster.enable =
    mkEnableOption (mdDoc "hamster, a time tracking program");

  config = mkIf config.programs.hamster.enable {
    environment.systemPackages = [ pkgs.hamster ];
    services.dbus.packages = [ pkgs.hamster ];
  };
}
