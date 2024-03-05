{ config, lib, pkgs, ... }:

let
  inherit (lib)
    escapeShellArg
    escapeShellArgs
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optional
    optionals
    optionalString
    types
    ;

  cfg = config.services.pixiecore;
in
{
  meta.maintainers = with maintainers; [ bbigras danderson ];

  options = {
    services.pixiecore = {
      enable = mkEnableOption (mdDoc "Pixiecore");

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Open ports (67, 69, 4011 UDP and 'port', 'statusPort' TCP) in the firewall for Pixiecore.
        '';
      };

      mode = mkOption {
        description = mdDoc "Which mode to use";
        default = "boot";
        type = types.enum [ "api" "boot" "quick" ];
      };

      debug = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Log more things that aren't directly related to booting a recognized client";
      };

      dhcpNoBind = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Handle DHCP traffic without binding to the DHCP server port";
      };

      quick = mkOption {
        description = mdDoc "Which quick option to use";
        default = "xyz";
        type = types.enum [ "arch" "centos" "coreos" "debian" "fedora" "ubuntu" "xyz" ];
      };

      kernel = mkOption {
        type = types.str or types.path;
        default = "";
        description = mdDoc "Kernel path. Ignored unless mode is set to 'boot'";
      };

      initrd = mkOption {
        type = types.str or types.path;
        default = "";
        description = mdDoc "Initrd path. Ignored unless mode is set to 'boot'";
      };

      cmdLine = mkOption {
        type = types.str;
        default = "";
        description = mdDoc "Kernel commandline arguments. Ignored unless mode is set to 'boot'";
      };

      listen = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = mdDoc "IPv4 address to listen on";
      };

      port = mkOption {
        type = types.port;
        default = 80;
        description = mdDoc "Port to listen on for HTTP";
      };

      statusPort = mkOption {
        type = types.port;
        default = 80;
        description = mdDoc "HTTP port for status information (can be the same as --port)";
      };

      apiServer = mkOption {
        type = types.str;
        example = "localhost:8080";
        description = mdDoc "host:port to connect to the API. Ignored unless mode is set to 'api'";
      };

      extraArguments = mkOption {
        type = types.listOf types.str;
        default = [];
        description = mdDoc "Additional command line arguments to pass to Pixiecore";
      };
    };
  };

  config = mkIf cfg.enable {
    users.groups.pixiecore = {};
    users.users.pixiecore = {
      description = "Pixiecore daemon user";
      group = "pixiecore";
      isSystemUser = true;
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port cfg.statusPort ];
      allowedUDPPorts = [ 67 69 4011 ];
    };

    systemd.services.pixiecore = {
      description = "Pixiecore server";
      after = [ "network.target"];
      wants = [ "network.target"];
      wantedBy = [ "multi-user.target"];
      serviceConfig = {
        User = "pixiecore";
        Restart = "always";
        AmbientCapabilities = [ "cap_net_bind_service" ] ++ optional cfg.dhcpNoBind "cap_net_raw";
        ExecStart =
          let
            argString =
              if cfg.mode == "boot"
              then [ "boot" cfg.kernel ]
                   ++ optional (cfg.initrd != "") cfg.initrd
                   ++ optionals (cfg.cmdLine != "") [ "--cmdline" cfg.cmdLine ]
              else if cfg.mode == "quick"
              then [ "quick" cfg.quick ]
              else [ "api" cfg.apiServer ];
          in
            ''
              ${pkgs.pixiecore}/bin/pixiecore \
                ${escapeShellArgs argString} \
                ${optionalString cfg.debug "--debug"} \
                ${optionalString cfg.dhcpNoBind "--dhcp-no-bind"} \
                --listen-addr ${escapeShellArg cfg.listen} \
                --port ${toString cfg.port} \
                --status-port ${toString cfg.statusPort} \
                ${escapeShellArgs cfg.extraArguments}
              '';
      };
    };
  };
}
