{ config, pkgs, lib, ... }:

let
  inherit (lib)
    attrsets
    concatMapAttrs
    concatStringsSep
    generators
    literalExpression
    mapAttrs'
    mapAttrsToList
    mdDoc
    mergeAttrsList
    mkIf
    mkOption
    mkRemovedOptionModule
    nameValuePair
    optionalAttrs
    optionals
    types
    versions
    ;

  im = config.i18n.inputMethod;

  cfg = im.fcitx5;

  fcitx5Package =
    if cfg.plasma6Support
    then pkgs.qt6Packages.fcitx5-with-addons.override { inherit (cfg) addons; }
    else pkgs.libsForQt5.fcitx5-with-addons.override { inherit (cfg) addons; };

  settingsFormat = pkgs.formats.ini { };
in
{
  options = {
    i18n.inputMethod.fcitx5 = {
      addons = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "with pkgs; [ fcitx5-rime ]";
        description = mdDoc ''
          Enabled Fcitx5 addons.
        '';
      };
      waylandFrontend = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Use the Wayland input method frontend.
          See [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland).
        '';
      };
      plasma6Support = mkOption {
        type = types.bool;
        default = config.services.xserver.desktopManager.plasma6.enable;
        defaultText = literalExpression "config.services.xserver.desktopManager.plasma6.enable";
        description = mdDoc ''
          Use qt6 versions of fcitx5 packages.
          Required for configuring fcitx5 in KDE System Settings.
        '';
      };
      quickPhrase = mkOption {
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            smile = "（・∀・）";
            angry = "(￣ー￣)";
          }
        '';
        description = mdDoc "Quick phrases.";
      };
      quickPhraseFiles = mkOption {
        type = with types; attrsOf path;
        default = { };
        example = literalExpression ''
          {
            words = ./words.mb;
            numbers = ./numbers.mb;
          }
        '';
        description = mdDoc "Quick phrase files.";
      };
      settings = {
        globalOptions = mkOption {
          type = types.submodule {
            freeformType = settingsFormat.type;
          };
          default = { };
          description = mdDoc ''
            The global options in `config` file in ini format.
          '';
        };
        inputMethod = mkOption {
          type = types.submodule {
            freeformType = settingsFormat.type;
          };
          default = { };
          description = mdDoc ''
            The input method configure in `profile` file in ini format.
          '';
        };
        addons = mkOption {
          type = with types; (attrsOf anything);
          default = { };
          description = mdDoc ''
            The addon configures in `conf` folder in ini format with global sections.
            Each item is written to the corresponding file.
          '';
          example = literalExpression "{ pinyin.globalSection.EmojiEnabled = \"True\"; }";
        };
      };
      ignoreUserConfig = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc ''
          Ignore the user configures. **Warning**: When this is enabled, the
          user config files are totally ignored and the user dict can't be saved
          and loaded.
        '';
      };
    };
  };

  imports = [
    (mkRemovedOptionModule [ "i18n" "inputMethod" "fcitx5" "enableRimeData" ] ''
      RIME data is now included in `fcitx5-rime` by default, and can be customized using `fcitx5-rime.override { rimeDataPkgs = ...; }`
    '')
  ];

  config = mkIf (im.enabled == "fcitx5") {
    i18n.inputMethod.package = fcitx5Package;

    i18n.inputMethod.fcitx5.addons = optionals (cfg.quickPhrase != { }) [
      (pkgs.writeTextDir "share/fcitx5/data/QuickPhrase.mb"
        (concatStringsSep "\n"
          (mapAttrsToList (name: value: "${name} ${value}") cfg.quickPhrase)))
    ] ++ optionals (cfg.quickPhraseFiles != { }) [
      (pkgs.linkFarm "quickPhraseFiles" (mapAttrs'
        (name: value: nameValuePair ("share/fcitx5/data/quickphrase.d/${name}.mb") value)
        cfg.quickPhraseFiles))
    ];
    environment.etc =
      let
        optionalFile = p: f: v: optionalAttrs (v != { }) {
          "xdg/fcitx5/${p}".text = f v;
        };
      in
      attrsets.mergeAttrsList [
        (optionalFile "config" (generators.toINI { }) cfg.settings.globalOptions)
        (optionalFile "profile" (generators.toINI { }) cfg.settings.inputMethod)
        (concatMapAttrs
          (name: value: optionalFile
            "conf/${name}.conf"
            (generators.toINIWithGlobalSection { })
            value)
          cfg.settings.addons)
      ];

    environment.variables = {
      XMODIFIERS = "@im=fcitx";
      QT_PLUGIN_PATH = [ "${fcitx5Package}/${pkgs.qt6.qtbase.qtPluginPrefix}" ];
    } // optionalAttrs (!cfg.waylandFrontend) {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
    } // optionalAttrs cfg.ignoreUserConfig {
      SKIP_FCITX_USER_PATH = "1";
    };
  };
}
