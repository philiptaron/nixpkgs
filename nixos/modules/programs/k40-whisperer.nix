{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
in

let
  cfg = config.programs.k40-whisperer;
  pkg = cfg.package.override {
    udevGroup = cfg.group;
  };
in
{
  options.programs.k40-whisperer = {
    enable = mkEnableOption (mdDoc "K40-Whisperer");

    group = mkOption {
      type = types.str;
      description = mdDoc ''
        Group assigned to the device when connected.
      '';
      default = "k40";
    };

    package = mkPackageOption pkgs "k40-whisperer" { };
  };

  config = mkIf cfg.enable {
    users.groups.${cfg.group} = {};

    environment.systemPackages = [ pkg ];
    services.udev.packages = [ pkg ];
  };
}
