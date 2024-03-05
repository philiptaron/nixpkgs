{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatMapStrings
    concatStringsSep
    maintainers
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    mkRenamedOptionModule
    optionalString
    types
    ;

  cfg = config.services.unclutter;

in {
  options.services.unclutter = {

    enable = mkOption {
      description = mdDoc "Enable unclutter to hide your mouse cursor when inactive";
      type = types.bool;
      default = false;
    };

    package = mkPackageOption pkgs "unclutter" { };

    keystroke = mkOption {
      description = mdDoc "Wait for a keystroke before hiding the cursor";
      type = types.bool;
      default = false;
    };

    timeout = mkOption {
      description = mdDoc "Number of seconds before the cursor is marked inactive";
      type = types.int;
      default = 1;
    };

    threshold = mkOption {
      description = mdDoc "Minimum number of pixels considered cursor movement";
      type = types.int;
      default = 1;
    };

    excluded = mkOption {
      description = mdDoc "Names of windows where unclutter should not apply";
      type = types.listOf types.str;
      default = [];
      example = [ "" ];
    };

    extraOptions = mkOption {
      description = mdDoc "More arguments to pass to the unclutter command";
      type = types.listOf types.str;
      default = [];
      example = [ "noevent" "grab" ];
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.unclutter = {
      description = "unclutter";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = ''
        ${cfg.package}/bin/unclutter \
          -idle ${toString cfg.timeout} \
          -jitter ${toString (cfg.threshold - 1)} \
          ${optionalString cfg.keystroke "-keystroke"} \
          ${concatMapStrings (x: " -"+x) cfg.extraOptions} \
          -not ${concatStringsSep " " cfg.excluded} \
      '';
      serviceConfig.PassEnvironment = "DISPLAY";
      serviceConfig.RestartSec = 3;
      serviceConfig.Restart = "always";
    };
  };

  imports = [
    (mkRenamedOptionModule [ "services" "unclutter" "threeshold" ]
                           [ "services"  "unclutter" "threshold" ])
  ];

  meta.maintainers = with maintainers; [ rnhmjoj ];

}
