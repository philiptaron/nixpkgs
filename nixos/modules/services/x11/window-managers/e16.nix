{ config , lib , pkgs , ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    singleton
    ;

  cfg = config.services.xserver.windowManager.e16;
in
{
  ###### interface
  options = {
    services.xserver.windowManager.e16.enable = mkEnableOption (mdDoc "e16");
  };

  ###### implementation
  config = mkIf cfg.enable {
    services.xserver.windowManager.session = singleton {
      name = "E16";
      start = ''
        ${pkgs.e16}/bin/e16 &
        waitPID=$!
      '';
    };

    environment.systemPackages = [ pkgs.e16 ];
  };
}
