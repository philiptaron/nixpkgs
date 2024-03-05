{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    mdDoc
    mkIf
    mkOption
    optionalString
    types
    ;

  inherit (pkgs) htpdate;

  cfg = config.services.htpdate;
in

{

  ###### interface

  options = {

    services.htpdate = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Enable htpdate daemon.
        '';
      };

      extraOptions = mkOption {
        type = types.str;
        default = "";
        description = mdDoc ''
          Additional command line arguments to pass to htpdate.
        '';
      };

      servers = mkOption {
        type = types.listOf types.str;
        default = [ "www.google.com" ];
        description = mdDoc ''
          HTTP servers to use for time synchronization.
        '';
      };

      proxy = mkOption {
        type = types.str;
        default = "";
        example = "127.0.0.1:8118";
        description = mdDoc ''
          HTTP proxy used for requests.
        '';
      };

    };

  };

  ###### implementation

  config = mkIf cfg.enable {

    systemd.services.htpdate = {
      description = "htpdate daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        PIDFile = "/run/htpdate.pid";
        ExecStart = concatStringsSep " " [
          "${htpdate}/bin/htpdate"
          "-D -u nobody"
          "-a -s"
          "-l"
          "${optionalString (cfg.proxy != "") "-P ${cfg.proxy}"}"
          "${cfg.extraOptions}"
          "${concatStringsSep " " cfg.servers}"
        ];
      };
    };

  };

}
