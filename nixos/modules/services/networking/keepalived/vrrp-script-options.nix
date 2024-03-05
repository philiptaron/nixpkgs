{ lib } :

let
  inherit (lib)
    literalExpression
    mdDoc
    mkOption
    types
    ;
in
{
  options = {

    script = mkOption {
      type = types.str;
      example = literalExpression ''"''${pkgs.curl} -f http://localhost:80"'';
      description = mdDoc "(Path of) Script command to execute followed by args, i.e. cmd [args]...";
    };

    interval = mkOption {
      type = types.int;
      default = 1;
      description = mdDoc "Seconds between script invocations.";
    };

    timeout = mkOption {
      type = types.int;
      default = 5;
      description = mdDoc "Seconds after which script is considered to have failed.";
    };

    weight = mkOption {
      type = types.int;
      default = 0;
      description = mdDoc "Following a failure, adjust the priority by this weight.";
    };

    rise = mkOption {
      type = types.int;
      default = 5;
      description = mdDoc "Required number of successes for OK transition.";
    };

    fall = mkOption {
      type = types.int;
      default = 3;
      description = mdDoc "Required number of failures for KO transition.";
    };

    user = mkOption {
      type = types.str;
      default = "keepalived_script";
      description = mdDoc "Name of user to run the script under.";
    };

    group = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = mdDoc "Name of group to run the script under. Defaults to user group.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = mdDoc "Extra lines to be added verbatim to the vrrp_script section.";
    };

  };

}
