# Munin-node module for Pepperfish

{ config, lib, hosts, ppfmisc, ... }:

with lib;

let
  cfg = config.pepperfish.munin-node;
  coreIP = escape [ "." ]
    (ppfmisc.internalIP hosts."${ppfmisc.munin-core}".hostNumber);
in {
  options.pepperfish.munin-node = {
    enable = mkEnableOption "enable munin-node";
  };

  config = mkIf (cfg.enable) {
    services.munin-node = {
      enable = true;
      extraConfig = ''
        allow ^${coreIP}$
      '';
    };
    networking.firewall.allowedTCPPorts = [ 4949 ];
  };
}
