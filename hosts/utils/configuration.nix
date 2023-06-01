# Utility system configuration
{ lib, config, pkgs, ... }:

let 
  machine = "utils";
in
{
  imports = [ ./hardware-configuration.nix ];

  zramSwap.enable = true;
  networking.hostName = machine;
  networking.domain = "";

  pepperfish.munin-node.enable = true;

  # Utils is the munin server so let's configure that here
  services.munin-cron = {
    enable = true;
    hosts = ''
      [plain;utils]
      address localhost
      [plain;services0]
      address 192.168.122.179
    '';
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "utils" = {
        serverAliases = [ "192.168.122.190" ];
        root = "/var/www/munin";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

}