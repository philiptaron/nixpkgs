{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.services.pdnsd;
  pdnsd = pkgs.pdnsd;
  pdnsdUser = "pdnsd";
  pdnsdGroup = "pdnsd";
  pdnsdConf = pkgs.writeText "pdnsd.conf"
    ''
      global {
        run_as=${pdnsdUser};
        cache_dir="${cfg.cacheDir}";
        ${cfg.globalConfig}
      }

      server {
        ${cfg.serverConfig}
      }
      ${cfg.extraConfig}
    '';
in

{ options =
    { services.pdnsd =
        { enable = mkEnableOption (mdDoc "pdnsd");

          cacheDir = mkOption {
            type = types.str;
            default = "/var/cache/pdnsd";
            description = mdDoc "Directory holding the pdnsd cache";
          };

          globalConfig = mkOption {
            type = types.lines;
            default = "";
            description = mdDoc ''
              Global configuration that should be added to the global directory
              of `pdnsd.conf`.
            '';
          };

          serverConfig = mkOption {
            type = types.lines;
            default = "";
            description = mdDoc ''
              Server configuration that should be added to the server directory
              of `pdnsd.conf`.
            '';
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = mdDoc ''
              Extra configuration directives that should be added to
              `pdnsd.conf`.
            '';
          };
        };
    };

  config = mkIf cfg.enable {
    users.users.${pdnsdUser} = {
      uid = config.ids.uids.pdnsd;
      group = pdnsdGroup;
      description = "pdnsd user";
    };

    users.groups.${pdnsdGroup} = {
      gid = config.ids.gids.pdnsd;
    };

    systemd.services.pdnsd =
      { wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        preStart =
          ''
            mkdir -p "${cfg.cacheDir}"
            touch "${cfg.cacheDir}/pdnsd.cache"
            chown -R ${pdnsdUser}:${pdnsdGroup} "${cfg.cacheDir}"
          '';
        description = "pdnsd";
        serviceConfig =
          {
            ExecStart = "${pdnsd}/bin/pdnsd -c ${pdnsdConf}";
          };
      };
  };
}
