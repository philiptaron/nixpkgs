{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    teams
    ;
in

{
  meta = {
    maintainers = teams.pantheon.members;
  };

  ###### interface
  options = {
    programs.pantheon-tweaks.enable = mkEnableOption (mdDoc "Pantheon Tweaks, an unofficial system settings panel for Pantheon");
  };

  ###### implementation
  config = mkIf config.programs.pantheon-tweaks.enable {
    services.xserver.desktopManager.pantheon.extraSwitchboardPlugs = [ pkgs.pantheon-tweaks ];
  };
}
