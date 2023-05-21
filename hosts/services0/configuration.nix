# Utility system configuration
{ lib, config, pkgs, ... }:

let 
  machine = "services0";
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.cleanTmpDir = true;
  zramSwap.enable = true;
  networking.hostName = machine;
  networking.domain = "";
  
  services.postgresql = {
    enable = true;
  };
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
  };

  pepperfish.munin-node.enable = true;

}