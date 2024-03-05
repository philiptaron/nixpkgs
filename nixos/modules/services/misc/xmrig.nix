{ config, pkgs, lib, ... }:

let
  inherit (lib)
    getExe
    literalExpression
    maintainers
    mdDoc
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    ;

  cfg = config.services.xmrig;

  json = pkgs.formats.json { };

  configFile = json.generate "config.json" cfg.settings;
in

{
  options = {
    services.xmrig = {
      enable = mkEnableOption (mdDoc "XMRig Mining Software");

      package = mkPackageOption pkgs "xmrig" {
        example = "xmrig-mo";
      };

      settings = mkOption {
        default = { };
        type = json.type;
        example = literalExpression ''
          {
            autosave = true;
            cpu = true;
            opencl = false;
            cuda = false;
            pools = [
              {
                url = "pool.supportxmr.com:443";
                user = "your-wallet";
                keepalive = true;
                tls = true;
              }
            ]
          }
        '';
        description = mdDoc ''
          XMRig configuration. Refer to
          <https://xmrig.com/docs/miner/config>
          for details on supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    hardware.cpu.x86.msr.enable = true;

    systemd.services.xmrig = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "XMRig Mining Software Service";
      serviceConfig = {
        ExecStartPre = "${getExe cfg.package} --config=${configFile} --dry-run";
        ExecStart = "${getExe cfg.package} --config=${configFile}";
        # https://xmrig.com/docs/miner/randomx-optimization-guide/msr
        # If you use recent XMRig with root privileges (Linux) or admin
        # privileges (Windows) the miner configure all MSR registers
        # automatically.
        DynamicUser = mkDefault false;
      };
    };
  };

  meta = {
    maintainers = with maintainers; [ ratsclub ];
  };
}
