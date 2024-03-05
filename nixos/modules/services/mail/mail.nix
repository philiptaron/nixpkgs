{ config, options, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    types
    ;
in

{

  ###### interface

  options = {

    services.mail = {

      sendmailSetuidWrapper = mkOption {
        type = types.nullOr options.security.wrappers.type.nestedTypes.elemType;
        default = null;
        internal = true;
        description = mdDoc ''
          Configuration for the sendmail setuid wapper.
        '';
      };

    };

  };

  ###### implementation

  config = mkIf (config.services.mail.sendmailSetuidWrapper != null) {

    security.wrappers.sendmail = config.services.mail.sendmailSetuidWrapper;

  };

}
