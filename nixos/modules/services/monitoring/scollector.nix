{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    literalExpression
    mapAttrsToList
    mdDoc
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.services.scollector;

  collectors = pkgs.runCommand "collectors" { preferLocalBuild = true; }
    ''
    mkdir -p $out
    ${concatStringsSep
        "\n"
        (mapAttrsToList
          (frequency: binaries:
            "mkdir -p $out/${frequency}\n" +
            (concatStringsSep
              "\n"
              (map (path: "ln -s ${path} $out/${frequency}/$(basename ${path})")
                   binaries)))
          cfg.collectors)}
    '';

  conf = pkgs.writeText "scollector.toml" ''
    Host = "${cfg.bosunHost}"
    ColDir = "${collectors}"
    ${cfg.extraConfig}
  '';

in {

  options = {

    services.scollector = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Whether to run scollector.
        '';
      };

      package = mkPackageOption pkgs "scollector" { };

      user = mkOption {
        type = types.str;
        default = "scollector";
        description = mdDoc ''
          User account under which scollector runs.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "scollector";
        description = mdDoc ''
          Group account under which scollector runs.
        '';
      };

      bosunHost = mkOption {
        type = types.str;
        default = "localhost:8070";
        description = mdDoc ''
          Host and port of the bosun server that will store the collected
          data.
        '';
      };

      collectors = mkOption {
        type = with types; attrsOf (listOf path);
        default = {};
        example = literalExpression ''{ "0" = [ "''${postgresStats}/bin/collect-stats" ]; }'';
        description = mdDoc ''
          An attribute set mapping the frequency of collection to a list of
          binaries that should be executed at that frequency. You can use "0"
          to run a binary forever.
        '';
      };

      extraOpts = mkOption {
        type = with types; listOf str;
        default = [];
        example = [ "-d" ];
        description = mdDoc ''
          Extra scollector command line options
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = mdDoc ''
          Extra scollector configuration added to the end of scollector.toml
        '';
      };

    };

  };

  config = mkIf config.services.scollector.enable {

    systemd.services.scollector = {
      description = "scollector metrics collector (part of Bosun)";
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.coreutils pkgs.iproute2 ];

      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/scollector -conf=${conf} ${concatStringsSep " " cfg.extraOpts}";
      };
    };

    users.users.scollector = {
      description = "scollector user";
      group = "scollector";
      uid = config.ids.uids.scollector;
    };

    users.groups.scollector.gid = config.ids.gids.scollector;

  };

}
