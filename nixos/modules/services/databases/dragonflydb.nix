{ config, lib, pkgs, ... }:

let
  inherit (lib)
    attrsets
    concatStringsSep
    escapeShellArg
    mapAttrsToList
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    strings
    types
    ;

  cfg = config.services.dragonflydb;

  dragonflydb = pkgs.dragonflydb;

  settings =
    {
      port = cfg.port;
      dir = "/var/lib/dragonflydb";
      keys_output_limit = cfg.keysOutputLimit;
    } //
    (optionalAttrs (cfg.bind != null) { bind = cfg.bind; }) //
    (optionalAttrs (cfg.requirePass != null) { requirepass = cfg.requirePass; }) //
    (optionalAttrs (cfg.maxMemory != null) { maxmemory = cfg.maxMemory; }) //
    (optionalAttrs (cfg.memcachePort != null) { memcache_port = cfg.memcachePort; }) //
    (optionalAttrs (cfg.dbNum != null) { dbnum = cfg.dbNum; }) //
    (optionalAttrs (cfg.cacheMode != null) { cache_mode = cfg.cacheMode; });
in
{

  ###### interface

  options = {
    services.dragonflydb = {
      enable = mkEnableOption (mdDoc "DragonflyDB");

      user = mkOption {
        type = types.str;
        default = "dragonfly";
        description = mdDoc "The user to run DragonflyDB as";
      };

      port = mkOption {
        type = types.port;
        default = 6379;
        description = mdDoc "The TCP port to accept connections.";
      };

      bind = mkOption {
        type = with types; nullOr str;
        default = "127.0.0.1";
        description = mdDoc ''
          The IP interface to bind to.
          `null` means "all interfaces".
        '';
      };

      requirePass = mkOption {
        type = with types; nullOr str;
        default = null;
        description = mdDoc "Password for database";
        example = "letmein!";
      };

      maxMemory = mkOption {
        type = with types; nullOr ints.unsigned;
        default = null;
        description = mdDoc ''
          The maximum amount of memory to use for storage (in bytes).
          `null` means this will be automatically set.
        '';
      };

      memcachePort = mkOption {
        type = with types; nullOr port;
        default = null;
        description = mdDoc ''
          To enable memcached compatible API on this port.
          `null` means disabled.
        '';
      };

      keysOutputLimit = mkOption {
        type = types.ints.unsigned;
        default = 8192;
        description = mdDoc ''
          Maximum number of returned keys in keys command.
          `keys` is a dangerous command.
          We truncate its result to avoid blowup in memory when fetching too many keys.
        '';
      };

      dbNum = mkOption {
        type = with types; nullOr ints.unsigned;
        default = null;
        description = mdDoc "Maximum number of supported databases for `select`";
      };

      cacheMode = mkOption {
        type = with types; nullOr bool;
        default = null;
        description = mdDoc ''
          Once this mode is on, Dragonfly will evict items least likely to be stumbled
          upon in the future but only when it is near maxmemory limit.
        '';
      };
    };
  };

  ###### implementation

  config = mkIf config.services.dragonflydb.enable {

    users.users = optionalAttrs (cfg.user == "dragonfly") {
      dragonfly.description = "DragonflyDB server user";
      dragonfly.isSystemUser = true;
      dragonfly.group = "dragonfly";
    };
    users.groups = optionalAttrs (cfg.user == "dragonfly") { dragonfly = { }; };

    environment.systemPackages = [ dragonflydb ];

    systemd.services.dragonflydb = {
      description = "DragonflyDB server";

      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${dragonflydb}/bin/dragonfly --alsologtostderr ${builtins.concatStringsSep " " (attrsets.mapAttrsToList (n: v: "--${n} ${strings.escapeShellArg v}") settings)}";

        User = cfg.user;

        # Filesystem access
        ReadWritePaths = [ settings.dir ];
        StateDirectory = "dragonflydb";
        StateDirectoryMode = "0700";
        # Process Properties
        LimitMEMLOCK = "infinity";
        # Caps
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        # Sandboxing
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictRealtime = true;
        PrivateMounts = true;
        MemoryDenyWriteExecute = true;
      };
    };
  };
}
