{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.criu;
in
{
  options = {
    programs.criu = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Install {command}`criu` along with necessary kernel options.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    system.requiredKernelConfig = with config.kernelConfig; [
      (isYes "CHECKPOINT_RESTORE")
    ];
    boot.kernel.features.criu = true;
    environment.systemPackages = [ pkgs.criu ];
  };

}
