# CFS Zen Tweaks

{ config, pkgs, lib, ... }:

let
  inherit (lib)
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    ;

  cfg = config.programs.cfs-zen-tweaks;

in

{

  meta = {
    maintainers = with maintainers; [ mkg20001 ];
  };

  options = {
    programs.cfs-zen-tweaks.enable = mkEnableOption (mdDoc "CFS Zen Tweaks");
  };

  config = mkIf cfg.enable {
    systemd.packages = [ pkgs.cfs-zen-tweaks ];

    systemd.services.set-cfs-tweaks.wantedBy = [
      "multi-user.target"
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
  };
}
