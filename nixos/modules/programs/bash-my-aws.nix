{ config, pkgs, lib, ... }:

let
  inherit (lib)
    init
    mdDoc
    mkEnableOption
    mkIf
    ;

  prg = config.programs;
  cfg = prg.bash-my-aws;

  initScript = ''
    eval $(${pkgs.bash-my-aws}/bin/bma-init)
  '';
in
  {
    options = {
      programs.bash-my-aws = {
        enable = mkEnableOption (mdDoc "bash-my-aws");
      };
    };

    config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [ bash-my-aws ];

      programs.bash.interactiveShellInit = initScript;
    };
  }
