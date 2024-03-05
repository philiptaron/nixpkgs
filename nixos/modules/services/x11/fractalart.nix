{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.services.fractalart;
in {
  options.services.fractalart = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = mdDoc "Enable FractalArt for generating colorful wallpapers on login";
    };

    width = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1920;
      description = mdDoc "Screen width";
    };

    height = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1080;
      description = mdDoc "Screen height";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.haskellPackages.FractalArt ];
    services.xserver.displayManager.sessionCommands =
      "${pkgs.haskellPackages.FractalArt}/bin/FractalArt --no-bg -f .background-image"
        + optionalString (cfg.width  != null) " -w ${toString cfg.width}"
        + optionalString (cfg.height != null) " -h ${toString cfg.height}";
  };
}
