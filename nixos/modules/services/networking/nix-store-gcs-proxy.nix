{ config, lib, pkgs, ... }:

let
  inherit (lib)
    filterAttrs
    maintainers
    mapAttrsToList
    mdDoc
    mkMerge
    mkOption
    types
    ;

  opts = { name, config, ... }: {
    options = {
      enable = mkOption {
        default = true;
        type = types.bool;
        example = true;
        description = mdDoc "Whether to enable proxy for this bucket";
      };
      bucketName = mkOption {
        type = types.str;
        default = name;
        example = "my-bucket-name";
        description = mdDoc "Name of Google storage bucket";
      };
      address = mkOption {
        type = types.str;
        example = "localhost:3000";
        description = mdDoc "The address of the proxy.";
      };
    };
  };
  enabledProxies = filterAttrs (n: v: v.enable) config.services.nix-store-gcs-proxy;
  mapProxies = function: mkMerge (mapAttrsToList function enabledProxies);
in
{
  options.services.nix-store-gcs-proxy = mkOption {
    type = types.attrsOf (types.submodule opts);
    default = {};
    description = mdDoc ''
      An attribute set describing an HTTP to GCS proxy that allows us to use GCS
      bucket via HTTP protocol.
    '';
  };

  config.systemd.services = mapProxies (name: cfg: {
    "nix-store-gcs-proxy-${name}" = {
      description = "A HTTP nix store that proxies requests to Google Storage";
      wantedBy = ["multi-user.target"];

      startLimitIntervalSec = 10;
      serviceConfig = {
        RestartSec = 5;
        ExecStart = ''
          ${pkgs.nix-store-gcs-proxy}/bin/nix-store-gcs-proxy \
            --bucket-name ${cfg.bucketName} \
            --addr ${cfg.address}
        '';

        DynamicUser = true;

        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateUsers = true;

        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;

        NoNewPrivileges = true;
        LockPersonality = true;
        RestrictRealtime = true;
      };
    };
  });

  meta.maintainers = [ maintainers.mrkkrp ];
}
