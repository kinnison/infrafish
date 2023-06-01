# Munin-node module for Pepperfish

{ config, lib, ... }:

with lib;

let cfg = config.pepperfish.munin-node;
in {
  options.pepperfish.munin-node = {
    enable = mkEnableOption "enable munin-node";
  };

  config = mkIf (cfg.enable) {
    services.munin-node = {
      enable = true;
      extraConfig = ''
        allow 192.168.122.190
      '';
    };
    networking.firewall.allowedTCPPorts = [ 4949 ];
  };
}
