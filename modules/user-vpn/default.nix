{ config, lib, pkgs, nodeName, ppfmisc, ... }:

with lib;
let
  wgPort = 51821;
  networkPrefix = "10.105.103";
  networkIP = nr: "${networkPrefix}.${builtins.toString nr}/24";
  hostIP = nr: "${networkPrefix}.${builtins.toString nr}/32";
in {
  config = mkIf (nodeName == "shell") {
    sops.secrets.user-vpn-master-key = {
      sopsFile = ../../keys/user-vpn-master-key;
      format = "binary";
    };
    networking.firewall.allowedUDPPorts = [ wgPort ];
    networking.firewall.trustedInterfaces = [ "wg1" ];
    networking.wireguard.interfaces = {
      wg1 = {
        ips = [ (networkIP ppfmisc.user-vpn.root.nodeNumber) ];
        listenPort = wgPort;
        privateKeyFile = config.sops.secrets.user-vpn-master-key.path;
        peers = map (entry: {
          publicKey = entry.pubkey;
          allowedIPs = [ (hostIP entry.nodeNumber) ];
        }) ppfmisc.user-vpn.hosts;
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${
            networkIP 0
          } -o ens2 -j MASQUERADE
        '';
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${
            networkIP 0
          } -o ens2 -j MASQUERADE
        '';
      };
    };
    # So that the wireguard can route between endpoints
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = [ "${networkPrefix}.1" ];
          access-control = [ "127.0.0.1/8 allow" "${networkIP 0} allow" ];
        };
      };
    };
  };
}
