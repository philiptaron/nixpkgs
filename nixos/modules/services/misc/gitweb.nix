{ config, lib, pkgs, ... }:

let
  inherit (lib)
    literalMD
    mdDoc
    mkOption
    types
    ;

  cfg = config.services.gitweb;

in
{

  options.services.gitweb = {

    projectroot = mkOption {
      default = "/srv/git";
      type = types.path;
      description = mdDoc ''
        Path to git projects (bare repositories) that should be served by
        gitweb. Must not end with a slash.
      '';
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = mdDoc ''
        Verbatim configuration text appended to the generated gitweb.conf file.
      '';
      example = ''
        $feature{'highlight'}{'default'} = [1];
        $feature{'ctags'}{'default'} = [1];
        $feature{'avatar'}{'default'} = ['gravatar'];
      '';
    };

    gitwebTheme = mkOption {
      default = false;
      type = types.bool;
      description = mdDoc ''
        Use an alternative theme for gitweb, strongly inspired by GitHub.
      '';
    };

    gitwebConfigFile = mkOption {
      default = pkgs.writeText "gitweb.conf" ''
        # path to git projects (<project>.git)
        $projectroot = "${cfg.projectroot}";
        $highlight_bin = "${pkgs.highlight}/bin/highlight";
        ${cfg.extraConfig}
      '';
      defaultText = literalMD "generated config file";
      type = types.path;
      readOnly = true;
      internal = true;
    };

  };
}
