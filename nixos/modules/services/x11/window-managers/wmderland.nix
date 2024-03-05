{ config, lib, pkgs, ... }:

let
  inherit (lib)
    literalExpression
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    singleton
    types
    ;

  cfg = config.services.xserver.windowManager.wmderland;
in

{
  options.services.xserver.windowManager.wmderland = {
    enable = mkEnableOption (mdDoc "wmderland");

    extraSessionCommands = mkOption {
      default = "";
      type = types.lines;
      description = mdDoc ''
        Shell commands executed just before wmderland is started.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = with pkgs; [
        rofi
        dunst
        light
        hsetroot
        feh
        rxvt-unicode
      ];
      defaultText = literalExpression ''
        with pkgs; [
          rofi
          dunst
          light
          hsetroot
          feh
          rxvt-unicode
        ]
      '';
      description = mdDoc ''
        Extra packages to be installed system wide.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "wmderland";
      start = ''
        ${cfg.extraSessionCommands}

        ${pkgs.wmderland}/bin/wmderland &
        waitPID=$!
      '';
    };
    environment.systemPackages = [
      pkgs.wmderland pkgs.wmderlandc
    ] ++ cfg.extraPackages;
  };
}
