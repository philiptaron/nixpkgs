# Tracker daemon.

{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkRenamedOptionModule
    teams
    types
    ;

  cfg = config.services.gnome.tracker;
in
{

  meta = {
    maintainers = teams.gnome.members;
  };

  imports = [
    # Added 2021-05-07
    (mkRenamedOptionModule
      [ "services" "gnome3" "tracker" "enable" ]
      [ "services" "gnome" "tracker" "enable" ]
    )
  ];

  ###### interface

  options = {

    services.gnome.tracker = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to enable Tracker services, a search engine,
          search tool and metadata storage system.
        '';
      };

      subcommandPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        internal = true;
        description = mdDoc ''
          List of packages containing tracker3 subcommands.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.tracker ];

    services.dbus.packages = [ pkgs.tracker ];

    systemd.packages = [ pkgs.tracker ];

    environment.variables = {
      TRACKER_CLI_SUBCOMMANDS_DIR =
        let
          subcommandPackagesTree = pkgs.symlinkJoin {
            name = "tracker-with-subcommands-${pkgs.tracker.version}";
            paths = [ pkgs.tracker ] ++ cfg.subcommandPackages;
          };
        in
        "${subcommandPackagesTree}/libexec/tracker3";
    };

  };

}
