{ config, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.systemtap;
in
{
  options = {
    programs.systemtap = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Install {command}`systemtap` along with necessary kernel options.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    system.requiredKernelConfig = with config.kernelConfig; [
      (isYes "DEBUG")
    ];
    boot.kernel.features.debug = true;
    environment.systemPackages = [
      config.boot.kernelPackages.systemtap
    ];
  };

}
