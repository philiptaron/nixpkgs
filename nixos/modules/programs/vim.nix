{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkOverride
    mkPackageOption
    types
    ;

  cfg = config.programs.vim;
in
{
  options.programs.vim = {
    defaultEditor = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        When enabled, installs vim and configures vim to be the default editor
        using the EDITOR environment variable.
      '';
    };

    package = mkPackageOption pkgs "vim" {
      example = "vim-full";
    };
  };

  config = mkIf cfg.defaultEditor {
    environment.systemPackages = [ cfg.package ];
    environment.variables = { EDITOR = mkOverride 900 "vim"; };
  };
}
