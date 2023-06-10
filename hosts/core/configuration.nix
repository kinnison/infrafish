# Utility system configuration
{ lib, config, pkgs, nodeData, hosts, ppfmisc, ... }:
with lib;
let
  systems = concatStrings (mapAttrsToList (n: d:
    let
      hostIP = ppfmisc.internalIP d.hostNumber;
      group = if d ? munin-group then d.munin-group else "plain";
    in ''
      [${group};${n}]
      address ${hostIP}

    '') hosts);
in {
  imports = [ ./hardware-configuration.nix ./networking.nix ];

  zramSwap.enable = true;

  pepperfish.munin-node.enable = true;

  # Utils is the munin server so let's configure that here
  services.munin-cron = {
    enable = true;
    hosts = systems;
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "core" = {
        serverAliases =
          [ nodeData.ip (ppfmisc.internalIP nodeData.hostNumber) ];
        root = "/var/www/munin";
      };
    };
  };

  services.postgresql = { enable = true; };
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

}
