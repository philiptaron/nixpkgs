{ lib, pkgs, config, ... }:

let
  inherit (lib)
    escapeShellArg
    maintainers
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optionalString
    types
    ;

  cfg = config.services.zfs.autoReplication;
  recursive = optionalString cfg.recursive " --recursive";
  followDelete = optionalString cfg.followDelete " --follow-delete";
in
{
  options = {
    services.zfs.autoReplication = {
      enable = mkEnableOption (mdDoc "ZFS snapshot replication");

      followDelete = mkOption {
        description = mdDoc "Remove remote snapshots that don't have a local correspondent.";
        default = true;
        type = types.bool;
      };

      host = mkOption {
        description = mdDoc "Remote host where snapshots should be sent. `lz4` is expected to be installed on this host.";
        example = "example.com";
        type = types.str;
      };

      identityFilePath = mkOption {
        description = mdDoc "Path to SSH key used to login to host.";
        example = "/home/username/.ssh/id_rsa";
        type = types.path;
      };

      localFilesystem = mkOption {
        description = mdDoc "Local ZFS filesystem from which snapshots should be sent.  Defaults to the attribute name.";
        example = "pool/file/path";
        type = types.str;
      };

      remoteFilesystem = mkOption {
        description = mdDoc "Remote ZFS filesystem where snapshots should be sent.";
        example = "pool/file/path";
        type = types.str;
      };

      recursive = mkOption {
        description = mdDoc "Recursively discover snapshots to send.";
        default = true;
        type = types.bool;
      };

      username = mkOption {
        description = mdDoc "Username used by SSH to login to remote host.";
        example = "username";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.lz4
    ];

    systemd.services.zfs-replication = {
      after = [
        "zfs-snapshot-daily.service"
        "zfs-snapshot-frequent.service"
        "zfs-snapshot-hourly.service"
        "zfs-snapshot-monthly.service"
        "zfs-snapshot-weekly.service"
      ];
      description = "ZFS Snapshot Replication";
      documentation = [
        "https://github.com/alunduil/zfs-replicate"
      ];
      restartIfChanged = false;
      serviceConfig.ExecStart = "${pkgs.zfs-replicate}/bin/zfs-replicate${recursive} -l ${escapeShellArg cfg.username} -i ${escapeShellArg cfg.identityFilePath}${followDelete} ${escapeShellArg cfg.host} ${escapeShellArg cfg.remoteFilesystem} ${escapeShellArg cfg.localFilesystem}";
      wantedBy = [
        "zfs-snapshot-daily.service"
        "zfs-snapshot-frequent.service"
        "zfs-snapshot-hourly.service"
        "zfs-snapshot-monthly.service"
        "zfs-snapshot-weekly.service"
      ];
    };
  };

  meta = {
    maintainers = with maintainers; [ alunduil ];
  };
}
