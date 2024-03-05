# Fusion Inventory daemon.
{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.fusionInventory;

  configFile = pkgs.writeText "fusion_inventory.conf" ''
    server = ${concatStringsSep ", " cfg.servers}

    logger = stderr

    ${cfg.extraConfig}
  '';

in
{

  ###### interface

  options = {

    services.fusionInventory = {

      enable = mkEnableOption (mdDoc "Fusion Inventory Agent");

      servers = mkOption {
        type = types.listOf types.str;
        description = mdDoc ''
          The urls of the OCS/GLPI servers to connect to.
        '';
      };

      extraConfig = mkOption {
        default = "";
        type = types.lines;
        description = mdDoc ''
          Configuration that is injected verbatim into the configuration file.
        '';
      };
    };
  };


  ###### implementation

  config = mkIf cfg.enable {

    users.users.fusion-inventory = {
      description = "FusionInventory user";
      isSystemUser = true;
    };

    systemd.services.fusion-inventory = {
      description = "Fusion Inventory Agent";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.fusionInventory}/bin/fusioninventory-agent --conf-file=${configFile} --daemon --no-fork";
      };
    };
  };
}
