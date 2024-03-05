{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    literalExpression
    makeBinPath
    mapAttrsToList
    mdDoc
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    optionalAttrs
    optionalString
    types
    ;

  cfg = config.services.node-red;
  defaultUser = "node-red";
  finalPackage = if cfg.withNpmAndGcc then node-red_withNpmAndGcc else cfg.package;
  node-red_withNpmAndGcc = pkgs.runCommand "node-red" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${pkgs.nodePackages.node-red}/bin/node-red $out/bin/node-red \
      --set PATH '${makeBinPath [ pkgs.nodePackages.npm pkgs.gcc ]}:$PATH' \
  '';
in
{
  options.services.node-red = {
    enable = mkEnableOption (mdDoc "the Node-RED service");

    package = mkPackageOption pkgs [ "nodePackages" "node-red" ] { };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Open ports in the firewall for the server.
      '';
    };

    withNpmAndGcc = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Give Node-RED access to NPM and GCC at runtime, so 'Nodes' can be
        downloaded and managed imperatively via the 'Palette Manager'.
      '';
    };

    configFile = mkOption {
      type = types.path;
      default = "${cfg.package}/lib/node_modules/node-red/settings.js";
      defaultText = literalExpression ''"''${package}/lib/node_modules/node-red/settings.js"'';
      description = mdDoc ''
        Path to the JavaScript configuration file.
        See <https://github.com/node-red/node-red/blob/master/packages/node_modules/node-red/settings.js>
        for a configuration example.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 1880;
      description = mdDoc "Listening port.";
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = mdDoc ''
        User under which Node-RED runs.If left as the default value this user
        will automatically be created on system activation, otherwise the
        sysadmin is responsible for ensuring the user exists.
      '';
    };

    group = mkOption {
      type = types.str;
      default = defaultUser;
      description = mdDoc ''
        Group under which Node-RED runs.If left as the default value this group
        will automatically be created on system activation, otherwise the
        sysadmin is responsible for ensuring the group exists.
      '';
    };

    userDir = mkOption {
      type = types.path;
      default = "/var/lib/node-red";
      description = mdDoc ''
        The directory to store all user data, such as flow and credential files and all library data. If left
        as the default value this directory will automatically be created before the node-red service starts,
        otherwise the sysadmin is responsible for ensuring the directory exists with appropriate ownership
        and permissions.
      '';
    };

    safe = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Whether to launch Node-RED in --safe mode.";
    };

    define = mkOption {
      type = types.attrs;
      default = {};
      description = mdDoc "List of settings.js overrides to pass via -D to Node-RED.";
      example = literalExpression ''
        {
          "logging.console.level" = "trace";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users = optionalAttrs (cfg.user == defaultUser) {
      ${defaultUser} = {
        isSystemUser = true;
        group = defaultUser;
      };
    };

    users.groups = optionalAttrs (cfg.group == defaultUser) {
      ${defaultUser} = { };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    systemd.services.node-red = {
      description = "Node-RED Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      environment = {
        HOME = cfg.userDir;
      };
      serviceConfig = mkMerge [
        {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${finalPackage}/bin/node-red ${pkgs.optionalString cfg.safe "--safe"} --settings ${cfg.configFile} --port ${toString cfg.port} --userDir ${cfg.userDir} ${concatStringsSep " " (mapAttrsToList (name: value: "-D ${name}=${value}") cfg.define)}";
          PrivateTmp = true;
          Restart = "always";
          WorkingDirectory = cfg.userDir;
        }
        (mkIf (cfg.userDir == "/var/lib/node-red") { StateDirectory = "node-red"; })
      ];
    };
  };
}
