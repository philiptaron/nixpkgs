{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  prg = config.programs;
  cfg = prg.thefuck;

  bashAndZshInitScript = ''
    eval $(${pkgs.thefuck}/bin/thefuck --alias ${cfg.alias})
  '';
  fishInitScript = ''
    ${pkgs.thefuck}/bin/thefuck --alias ${cfg.alias} | source
  '';
in
  {
    options = {
      programs.thefuck = {
        enable = mkEnableOption (mdDoc "thefuck");

        alias = mkOption {
          default = "fuck";
          type = types.str;

          description = mdDoc ''
            `thefuck` needs an alias to be configured.
            The default value is `fuck`, but you can use anything else as well.
          '';
        };
      };
    };

    config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ thefuck ];

      programs.bash.interactiveShellInit = bashAndZshInitScript;
      programs.zsh.interactiveShellInit = mkIf prg.zsh.enable bashAndZshInitScript;
      programs.fish.interactiveShellInit = mkIf prg.fish.enable fishInitScript;
    };
  }
