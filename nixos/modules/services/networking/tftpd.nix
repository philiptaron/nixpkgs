{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    singleton
    types
    ;
in

{

  ###### interface

  options = {

    services.tftpd.enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Whether to enable tftpd, a Trivial File Transfer Protocol server.
        The server will be run as an xinetd service.
      '';
    };

    services.tftpd.path = mkOption {
      type = types.path;
      default = "/srv/tftp";
      description = mdDoc ''
        Where the tftp server files are stored.
      '';
    };

  };


  ###### implementation

  config = mkIf config.services.tftpd.enable {

    services.xinetd.enable = true;

    services.xinetd.services = singleton
      { name = "tftp";
        protocol = "udp";
        server = "${pkgs.netkittftp}/sbin/in.tftpd";
        serverArgs = "${config.services.tftpd.path}";
      };

  };

}
