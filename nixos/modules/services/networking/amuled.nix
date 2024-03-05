{ config, lib, options, pkgs, ... }:

let
  inherit (lib)
    literalExpression
    mdDoc
    mkIf
    mkOption
    types
    ;

  cfg = config.services.amule;
  opt = options.services.amule;
  user = if cfg.user != null then cfg.user else "amule";
in

{

  ###### interface

  options = {

    services.amule = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to run the AMule daemon. You need to manually run "amuled --ec-config" to configure the service for the first time.
        '';
      };

      dataDir = mkOption {
        type = types.str;
        default = "/home/${user}/";
        defaultText = literalExpression ''
          "/home/''${config.${opt.user}}/"
        '';
        description = mdDoc ''
          The directory holding configuration, incoming and temporary files.
        '';
      };

      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc ''
          The user the AMule daemon should run as.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    users.users = mkIf (cfg.user == null) [
      { name = "amule";
        description = "AMule daemon";
        group = "amule";
        uid = config.ids.uids.amule;
      } ];

    users.groups = mkIf (cfg.user == null) [
      { name = "amule";
        gid = config.ids.gids.amule;
      } ];

    systemd.services.amuled = {
      description = "AMule daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      preStart = ''
        mkdir -p ${cfg.dataDir}
        chown ${user} ${cfg.dataDir}
      '';

      script = ''
        ${pkgs.su}/bin/su -s ${pkgs.runtimeShell} ${user} \
            -c 'HOME="${cfg.dataDir}" ${pkgs.amule-daemon}/bin/amuled'
      '';
    };
  };
}
