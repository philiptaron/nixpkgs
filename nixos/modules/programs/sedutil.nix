{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.sedutil;

in
{
  options.programs.sedutil.enable = mkEnableOption (mdDoc "sedutil");

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "libata.allow_tpm=1"
    ];

    environment.systemPackages = with pkgs; [ sedutil ];
  };
}
