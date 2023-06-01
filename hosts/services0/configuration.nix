# Utility system configuration
{ lib, config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  zramSwap.enable = true;

  services.postgresql = { enable = true; };
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
  };

  pepperfish.munin-node.enable = true;

}
