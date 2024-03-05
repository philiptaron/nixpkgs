{ lib, ... }:

let
  inherit (lib)
    mdDoc
    mkOption
    types
    ;
in

{
  options.boot.loader.efi = {

    canTouchEfiVariables = mkOption {
      default = false;
      type = types.bool;
      description = mdDoc "Whether the installation process is allowed to modify EFI boot variables.";
    };

    efiSysMountPoint = mkOption {
      default = "/boot";
      type = types.str;
      description = mdDoc "Where the EFI System Partition is mounted.";
    };
  };
}
