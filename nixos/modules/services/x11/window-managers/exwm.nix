{ config, lib, pkgs, ... }:

let
  inherit (lib)
    literalExpression
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionalString
    singleton
    types
    ;

  cfg = config.services.xserver.windowManager.exwm;
  loadScript = pkgs.writeText "emacs-exwm-load" ''
    ${cfg.loadScript}
    ${optionalString cfg.enableDefaultConfig ''
      (require 'exwm-config)
      (exwm-config-default)
    ''}
  '';
  packages = epkgs: cfg.extraPackages epkgs ++ [ epkgs.exwm ];
  exwm-emacs = pkgs.emacsWithPackages packages;
in

{
  options = {
    services.xserver.windowManager.exwm = {
      enable = mkEnableOption (mdDoc "exwm");
      loadScript = mkOption {
        default = "(require 'exwm)";
        type = types.lines;
        example = ''
          (require 'exwm)
          (exwm-enable)
        '';
        description = mdDoc ''
          Emacs lisp code to be run after loading the user's init
          file. If enableDefaultConfig is true, this will be run
          before loading the default config.
        '';
      };
      enableDefaultConfig = mkOption {
        default = true;
        type = types.bool;
        description = mdDoc "Enable an uncustomised exwm configuration.";
      };
      extraPackages = mkOption {
        type = types.functionTo (types.listOf types.package);
        default = epkgs: [];
        defaultText = literalExpression "epkgs: []";
        example = literalExpression ''
          epkgs: [
            epkgs.emms
            epkgs.magit
            epkgs.proofgeneral
          ]
        '';
        description = mdDoc ''
          Extra packages available to Emacs. The value must be a
          function which receives the attrset defined in
          {var}`emacs.pkgs` as the sole argument.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "exwm";
      start = ''
        ${exwm-emacs}/bin/emacs -l ${loadScript}
      '';
    };
    environment.systemPackages = [ exwm-emacs ];
  };
}
