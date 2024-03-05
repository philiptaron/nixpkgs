{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;
in
{
  options.services.sdrplayApi = {
    enable = mkOption {
      default = false;
      example = true;
      description = mdDoc ''
        Whether to enable the SDRplay API service and udev rules.

        ::: {.note}
        To enable integration with SoapySDR and GUI applications like gqrx create an overlay containing
        `soapysdr-with-plugins = super.soapysdr.override { extraPackages = [ super.soapysdrplay ]; };`
        :::
      '';
      type = types.bool;
    };
  };

  config = mkIf config.services.sdrplayApi.enable {
    systemd.services.sdrplayApi = {
      description = "SDRplay API Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.sdrplay}/bin/sdrplay_apiService";
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "1s";
      };
    };
    services.udev.packages = [ pkgs.sdrplay ];

  };
}
