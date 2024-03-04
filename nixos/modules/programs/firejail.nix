{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatStringsSep
    escapeShellArgs
    getBin
    isAttrs
    literalExpression
    maintainers
    mapAttrsToList
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalString
    types
    ;

  cfg = config.programs.firejail;

  wrappedBins = pkgs.runCommand "firejail-wrapped-binaries"
    { preferLocalBuild = true;
      allowSubstitutes = false;
      # take precedence over non-firejailed versions
      meta.priority = -1;
    }
    ''
      mkdir -p $out/bin
      mkdir -p $out/share/applications
      ${concatStringsSep "\n" (mapAttrsToList (command: value:
      let
        opts = if builtins.isAttrs value
        then value
        else { executable = value; desktop = null; profile = null; extraArgs = []; };
        args = escapeShellArgs (
          opts.extraArgs
          ++ (optional (opts.profile != null) "--profile=${toString opts.profile}")
        );
      in
      ''
        cat <<_EOF >$out/bin/${command}
        #! ${pkgs.runtimeShell} -e
        exec /run/wrappers/bin/firejail ${args} -- ${toString opts.executable} "\$@"
        _EOF
        chmod 0755 $out/bin/${command}

        ${optionalString (opts.desktop != null) ''
          substitute ${opts.desktop} $out/share/applications/$(basename ${opts.desktop}) \
            --replace ${opts.executable} $out/bin/${command}
        ''}
      '') cfg.wrappedBinaries)}
    '';

in {
  options.programs.firejail = {
    enable = mkEnableOption (mdDoc "firejail");

    wrappedBinaries = mkOption {
      type = types.attrsOf (types.either types.path (types.submodule {
        options = {
          executable = mkOption {
            type = types.path;
            description = mdDoc "Executable to run sandboxed";
            example = literalExpression ''"''${getBin pkgs.firefox}/bin/firefox"'';
          };
          desktop = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = mdDoc ".desktop file to modify. Only necessary if it uses the absolute path to the executable.";
            example = literalExpression ''"''${pkgs.firefox}/share/applications/firefox.desktop"'';
          };
          profile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = mdDoc "Profile to use";
            example = literalExpression ''"''${pkgs.firejail}/etc/firejail/firefox.profile"'';
          };
          extraArgs = mkOption {
            type = types.listOf types.str;
            default = [];
            description = mdDoc "Extra arguments to pass to firejail";
            example = [ "--private=~/.firejail_home" ];
          };
        };
      }));
      default = {};
      example = literalExpression ''
        {
          firefox = {
            executable = "''${getBin pkgs.firefox}/bin/firefox";
            profile = "''${pkgs.firejail}/etc/firejail/firefox.profile";
          };
          mpv = {
            executable = "''${getBin pkgs.mpv}/bin/mpv";
            profile = "''${pkgs.firejail}/etc/firejail/mpv.profile";
          };
        }
      '';
      description = mdDoc ''
        Wrap the binaries in firejail and place them in the global path.
      '';
    };
  };

  config = mkIf cfg.enable {
    security.wrappers.firejail =
      { setuid = true;
        owner = "root";
        group = "root";
        source = "${getBin pkgs.firejail}/bin/firejail";
      };

    environment.systemPackages = [ pkgs.firejail ] ++ [ wrappedBins ];
  };

  meta.maintainers = with maintainers; [ peterhoeg ];
}
