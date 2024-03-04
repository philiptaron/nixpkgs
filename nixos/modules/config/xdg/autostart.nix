{ config, lib, ... }:

let
  inherit (lib)
    mdDoc
    meta
    mkIf
    mkOption
    teams
    types
    ;
in
{
  meta = {
    maintainers = teams.freedesktop.members;
  };

  options = {
    xdg.autostart.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Whether to install files to support the
        [XDG Autostart specification](https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html).
      '';
    };
  };

  config = mkIf config.xdg.autostart.enable {
    environment.pathsToLink = [
      "/etc/xdg/autostart"
    ];
  };

}
