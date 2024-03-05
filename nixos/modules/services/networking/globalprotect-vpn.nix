{ config, lib, pkgs, ... }:

let
  inherit (lib)
    generators
    literalExpression
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.globalprotect;

  execStart =
    if cfg.csdWrapper == null then
      "${pkgs.globalprotect-openconnect}/bin/gpservice"
    else
      "${pkgs.globalprotect-openconnect}/bin/gpservice --csd-wrapper=${cfg.csdWrapper}";
in

{
  options.services.globalprotect = {
    enable = mkEnableOption (mdDoc "globalprotect");

    settings = mkOption {
      description = mdDoc ''
        GlobalProtect-openconnect configuration. For more information, visit
        <https://github.com/yuezk/GlobalProtect-openconnect/wiki/Configuration>.
      '';
      default = { };
      example = {
        "vpn1.company.com" = {
          openconnect-args = "--script=/path/to/vpnc-script";
        };
      };
      type = types.attrs;
    };

    csdWrapper = mkOption {
      description = mdDoc ''
        A script that will produce a Host Integrity Protection (HIP) report,
        as described at <https://www.infradead.org/openconnect/hip.html>
      '';
      default = null;
      example = literalExpression ''"''${pkgs.openconnect}/libexec/openconnect/hipreport.sh"'';
      type = types.nullOr types.path;
    };
  };

  config = mkIf cfg.enable {
    services.dbus.packages = [ pkgs.globalprotect-openconnect ];

    environment.etc."gpservice/gp.conf".text = generators.toINI { } cfg.settings;

    systemd.services.gpservice = {
      description = "GlobalProtect openconnect DBus service";
      serviceConfig = {
        Type = "dbus";
        BusName = "com.yuezk.qt.GPService";
        ExecStart = execStart;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
    };
  };
}
