{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;

  enable = config.programs.bash.enableLsColors;
in
{
  options = {
    programs.bash.enableLsColors = mkEnableOption (mdDoc "extra colors in directory listings") // {
      default = true;
    };
  };

  config = mkIf enable {
    programs.bash.promptPluginInit = ''
      eval "$(${pkgs.coreutils}/bin/dircolors -b)"
    '';
  };
}
