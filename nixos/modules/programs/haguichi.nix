{ lib, pkgs, config, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    ;
in

{
  options.programs.haguichi = {
    enable = mkEnableOption (mdDoc "Haguichi, a Linux GUI frontend to the proprietary LogMeIn Hamachi");
  };

  config = mkIf config.programs.haguichi.enable {
    environment.systemPackages = with pkgs; [ haguichi ];

    services.logmein-hamachi.enable = true;
  };
}
