{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.nbd;
in
{
  options = {
    programs.nbd = {
      enable = mkEnableOption (mdDoc "Network Block Device (nbd) support");
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nbd ];
    boot.kernelModules = [ "nbd" ];
  };
}
