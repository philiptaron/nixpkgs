{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkPackageOption
    ;

  cfg = config.programs.zsh.zsh-autoenv;
in
{
  options = {
    programs.zsh.zsh-autoenv = {
      enable = mkEnableOption (mdDoc "zsh-autoenv");
      package = mkPackageOption pkgs "zsh-autoenv" { };
    };
  };

  config = mkIf cfg.enable {
    programs.zsh.interactiveShellInit = ''
      source ${cfg.package}/share/zsh-autoenv/autoenv.zsh
    '';
  };
}
