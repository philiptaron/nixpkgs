{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.kbdlight;
in
{
  options.programs.kbdlight.enable = mkEnableOption (mdDoc "kbdlight");

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.kbdlight ];
    security.wrappers.kbdlight =
      { setuid = true;
        owner = "root";
        group = "root";
        source = "${pkgs.kbdlight.out}/bin/kbdlight";
      };
  };
}
