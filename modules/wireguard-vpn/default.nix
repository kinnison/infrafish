# Wireguard setup for Pepperfish

{ config, lib, nodeName, nodeData, inputs, ppfmisc, ... }:

with lib;
let
  wglib = import ./wg-lib.nix { inherit ppfmisc; };
  wgPort = 51820;
  myClients =
    filterAttrs (n: d: d ? vpn && d.vpn.core == nodeName) inputs.hosts;
  genCorePeers = mapAttrsToList (n: d: {
    publicKey = d.vpn.pubkey;
    allowedIPs = [ (wglib.host d.hostNumber) ];
  }) myClients;
  myCore = inputs.hosts."${nodeData.vpn.core}";
  genClientPeers = [{
    publicKey = myCore.vpn.pubkey;
    allowedIPs = [ (wglib.network 0) ];
    endpoint = "${myCore.ip}:${builtins.toString wgPort}";
    persistentKeepalive = 25;
  }];

  coreName = if nodeData.vpn.core == "" then nodeName else nodeData.vpn.core;
  allHostsInVPN =
    filterAttrs (n: d: d ? vpn && (n == coreName || d.vpn.core == coreName))
    inputs.hosts;

in {
  config = mkIf (nodeData ? vpn) {
    sops.secrets.wg_private = {
      sopsFile = ../../keys/hosts/${nodeName}_wg_keys.yaml;
    };
    networking.firewall.allowedUDPPorts = [ wgPort ];
    networking.wireguard.interfaces = {
      wg0 = {
        ips = [ (wglib.network nodeData.hostNumber) ];
        listenPort = wgPort;

        privateKeyFile = config.sops.secrets.wg_private.path;

        peers =
          if nodeData.vpn.core == "" then genCorePeers else genClientPeers;
      };
    };
    networking.hosts = mapAttrs' (n: d: {
      name = wglib.hostIP d.hostNumber;
      value = [ "${n}.vpn" ];
    }) allHostsInVPN;
  };
}
