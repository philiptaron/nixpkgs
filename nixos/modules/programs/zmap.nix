{ pkgs, config, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.zmap;
in
{
  options.programs.zmap = {
    enable = mkEnableOption (mdDoc "ZMap");
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.zmap ];

    environment.etc."zmap/blacklist.conf".source = "${pkgs.zmap}/etc/zmap/blacklist.conf";
    environment.etc."zmap/zmap.conf".source = "${pkgs.zmap}/etc/zmap.conf";
  };
}
