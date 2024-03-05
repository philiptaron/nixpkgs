{ lib, ... }:

let
  inherit (lib)
    mkOverride
    ;
in

{
  boot.loader.grub.device = mkOverride 0 "nodev";
  specialisation = mkOverride 0 {};
}
