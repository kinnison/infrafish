# Utility system configuration
{ lib, config, pkgs, nodeData, hosts, ppfmisc, ... }:
with lib;
let
  systems = concatStrings (mapAttrsToList (n: d:
    let
      hostIP = ppfmisc.internalIP d.hostNumber;
      group = if d ? munin-group then d.munin-group else "infrafish";
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
      "munin.infrafish.uk" = {
        onlySSL = true;
        useACMEHost = "munin.infrafish.uk";
        root = "/var/www/munin";
      };
    };
  };

  security.acme.certs = {
    "munin.infrafish.uk" = { group = config.services.nginx.group; };
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = ''
      host all all ${ppfmisc.internalIP 1}/24 trust
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
  };

  networking.firewall.allowedTCPPorts = [ 443 ];

}
