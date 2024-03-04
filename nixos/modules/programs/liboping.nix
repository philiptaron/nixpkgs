{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkMerge
    ;

  cfg = config.programs.liboping;
in
{
  options.programs.liboping = {
    enable = mkEnableOption (mdDoc "liboping");
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ liboping ];
    security.wrappers = mkMerge (map (
      exec: {
        "${exec}" = {
          owner = "root";
          group = "root";
          capabilities = "cap_net_raw+p";
          source = "${pkgs.liboping}/bin/${exec}";
        };
      }
    ) [ "oping" "noping" ]);
  };
}
