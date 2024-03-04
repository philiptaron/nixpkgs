{ lib, pkgs, config, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in
{
  options.programs.joycond-cemuhook = {
    enable = mkEnableOption (mdDoc "joycond-cemuhook, a program to enable support for cemuhook's UDP protocol for joycond devices.");
  };

  config = mkIf config.programs.joycond-cemuhook.enable {
    assertions = [
      {
        assertion = config.services.joycond.enable;
        message = "joycond must be enabled through `services.joycond.enable`";
      }
    ];
    environment.systemPackages = [ pkgs.joycond-cemuhook ];
  };
}
