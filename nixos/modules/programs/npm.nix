{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    misc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.npm;
in

{
  ###### interface

  options = {
    programs.npm = {
      enable = mkEnableOption (mdDoc "{command}`npm` global config");

      package = mkPackageOption pkgs [ "nodePackages" "npm" ] {
        example = "nodePackages_13_x.npm";
      };

      npmrc = mkOption {
        type = types.lines;
        description = mdDoc ''
          The system-wide npm configuration.
          See <https://docs.npmjs.com/misc/config>.
        '';
        default = ''
          prefix = ''${HOME}/.npm
        '';
        example = ''
          prefix = ''${HOME}/.npm
          https-proxy=proxy.example.com
          init-license=MIT
          init-author-url=https://www.npmjs.com/
          color=true
        '';
      };
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    environment.etc.npmrc.text = cfg.npmrc;

    environment.variables.NPM_CONFIG_GLOBALCONFIG = "/etc/npmrc";

    environment.systemPackages = [ cfg.package ];
  };

}
