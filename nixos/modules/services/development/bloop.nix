{ config, lib, pkgs, ... }:

let
  inherit (lib)
    makeBinPath
    mdDoc
    mkForce
    mkIf
    mkOption
    types
    ;

  cfg = config.services.bloop;

in
{

  options.services.bloop = {
    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "-J-Xmx2G"
        "-J-XX:MaxInlineLevel=20"
        "-J-XX:+UseParallelGC"
      ];
      description = mdDoc ''
        Specifies additional command line argument to pass to bloop
        java process.
      '';
    };

    install = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to install a user service for the Bloop server.

        The service must be manually started for each user with
        "systemctl --user start bloop".
      '';
    };
  };

  config = mkIf (cfg.install) {
    systemd.user.services.bloop = {
      description = "Bloop Scala build server";

      environment = {
        PATH = mkForce "${makeBinPath [ config.programs.java.package ]}";
      };
      serviceConfig = {
        Type        = "simple";
        ExecStart   = "${pkgs.bloop}/bin/bloop server";
        Restart     = "always";
      };
    };

    environment.systemPackages = [ pkgs.bloop ];
  };
}
