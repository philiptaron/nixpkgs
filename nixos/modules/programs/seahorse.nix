# Seahorse.

{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mdDoc
    mkDefault
    mkEnableOption
    mkIf
    mkRenamedOptionModule
    ;
in

{

 # Added 2019-08-27
  imports = [
    (mkRenamedOptionModule
      [ "services" "gnome3" "seahorse" "enable" ]
      [ "programs" "seahorse" "enable" ])
  ];


  ###### interface

  options = {

    programs.seahorse = {

      enable = mkEnableOption (mdDoc "Seahorse, a GNOME application for managing encryption keys and passwords in the GNOME Keyring");

    };

  };


  ###### implementation

  config = mkIf config.programs.seahorse.enable {

    programs.ssh.askPassword = mkDefault "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";

    environment.systemPackages = [
      pkgs.gnome.seahorse
    ];

    services.dbus.packages = [
      pkgs.gnome.seahorse
    ];

  };

}
