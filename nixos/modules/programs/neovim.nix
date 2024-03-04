{ config, lib, pkgs, ... }:

let
  inherit (lib)
    attrValues
    listToAttrs
    literalExpression
    mapAttrs
    mdDoc
    mkDefault
    mkIf
    mkOption
    mkOverride
    mkPackageOption
    optionals
    types
    ;

  cfg = config.programs.neovim;
in
{
  options.programs.neovim = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = mdDoc ''
        Whether to enable Neovim.

        When enabled through this option, Neovim is wrapped to use a
        configuration managed by this module. The configuration file in the
        user's home directory at {file}`~/.config/nvim/init.vim` is no longer
        loaded by default.
      '';
    };

    defaultEditor = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        When enabled, installs neovim and configures neovim to be the default editor
        using the EDITOR environment variable.
      '';
    };

    viAlias = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Symlink {command}`vi` to {command}`nvim` binary.
      '';
    };

    vimAlias = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Symlink {command}`vim` to {command}`nvim` binary.
      '';
    };

    withRuby = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Enable Ruby provider.";
    };

    withPython3 = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Enable Python 3 provider.";
    };

    withNodeJs = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Enable Node provider.";
    };

    configure = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          customRC = '''
            " here your custom configuration goes!
          ''';
          packages.myVimPackage = with pkgs.vimPlugins; {
            # loaded on launch
            start = [ fugitive ];
            # manually loadable by calling `:packadd $plugin-name`
            opt = [ ];
          };
        }
      '';
      description = mdDoc ''
        Generate your init file from your list of plugins and custom commands.
        Neovim will then be wrapped to load {command}`nvim -u /nix/store/«hash»-vimrc`
      '';
    };

    package = mkPackageOption pkgs "neovim-unwrapped" { };

    finalPackage = mkOption {
      type = types.package;
      visible = false;
      readOnly = true;
      description = mdDoc "Resulting customized neovim package.";
    };

    runtime = mkOption {
      default = { };
      example = literalExpression ''
        { "ftplugin/c.vim".text = "setlocal omnifunc=v:lua.vim.lsp.omnifunc"; }
      '';
      description = mdDoc ''
        Set of files that have to be linked in {file}`runtime`.
      '';

      type = with types; attrsOf (submodule (
        { name, config, ... }:
        {
          options = {

            enable = mkOption {
              type = types.bool;
              default = true;
              description = mdDoc ''
                Whether this runtime directory should be generated.  This
                option allows specific runtime files to be disabled.
              '';
            };

            target = mkOption {
              type = types.str;
              description = mdDoc ''
                Name of symlink.  Defaults to the attribute
                name.
              '';
            };

            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = mdDoc "Text of the file.";
            };

            source = mkOption {
              default = null;
              type = types.nullOr types.path;
              description = mdDoc "Path of the source file.";
            };

          };

          config.target = mkDefault name;
        }
      ));

    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.finalPackage
    ];
    environment.variables.EDITOR = mkIf cfg.defaultEditor (mkOverride 900 "nvim");

    environment.etc = listToAttrs (attrValues (mapAttrs
      (name: value: {
        name = "xdg/nvim/${name}";
        value = removeAttrs
          (value // {
            target = "xdg/nvim/${value.target}";
          })
          (optionals (isNull value.source) [ "source" ]);
      })
      cfg.runtime));

    programs.neovim.finalPackage = pkgs.wrapNeovim cfg.package {
      inherit (cfg) viAlias vimAlias withPython3 withNodeJs withRuby configure;
    };
  };
}
