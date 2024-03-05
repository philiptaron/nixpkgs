# Remote desktop daemon using Pipewire.
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkRenamedOptionModule
    teams
    ;
in

{
  meta = {
    maintainers = teams.gnome.members;
  };

  # Added 2021-05-07
  imports = [
    (mkRenamedOptionModule
      [ "services" "gnome3" "gnome-remote-desktop" "enable" ]
      [ "services" "gnome" "gnome-remote-desktop" "enable" ]
    )
  ];

  ###### interface
  options = {
    services.gnome.gnome-remote-desktop = {
      enable = mkEnableOption (mdDoc "Remote Desktop support using Pipewire");
    };
  };

  ###### implementation
  config = mkIf config.services.gnome.gnome-remote-desktop.enable {
    services.pipewire.enable = true;

    systemd.packages = [ pkgs.gnome.gnome-remote-desktop ];
  };
}
