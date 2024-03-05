{ config, lib, pkgs, ... }:

let
  inherit (lib)
    concatMapStrings
    literalExpression
    mdDoc
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optionalString
    singleton
    types
    ;

  cfg = config.services.xserver.windowManager.awesome;
  awesome = cfg.package;
  getLuaPath = lib: dir: "${lib}/${dir}/lua/${awesome.lua.luaversion}";
  makeSearchPath = concatMapStrings (path:
    " --search " + (getLuaPath path "share") +
    " --search " + (getLuaPath path "lib")
  );
in

{

  ###### interface

  options = {

    services.xserver.windowManager.awesome = {

      enable = mkEnableOption (mdDoc "Awesome window manager");

      luaModules = mkOption {
        default = [];
        type = types.listOf types.package;
        description = mdDoc "List of lua packages available for being used in the Awesome configuration.";
        example = literalExpression "[ pkgs.luaPackages.vicious ]";
      };

      package = mkPackageOption pkgs "awesome" { };

      noArgb = mkOption {
        default = false;
        type = types.bool;
        description = mdDoc "Disable client transparency support, which can be greatly detrimental to performance in some setups";
      };
    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    services.xserver.windowManager.session = singleton
      { name = "awesome";
        start =
          ''
            ${awesome}/bin/awesome ${optionalString cfg.noArgb "--no-argb"} ${makeSearchPath cfg.luaModules} &
            waitPID=$!
          '';
      };

    environment.systemPackages = [ awesome ];

  };
}
