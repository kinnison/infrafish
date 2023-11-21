{ config, lib, pkgs, nodeName, nodeData, inputs, ppfmisc, ... }:

with lib;
let
  store-port = 5349;
  has-vpn = nodeData ? vpn;
  all-nodes-except-me = filter (n: n != nodeName) (attrNames inputs.hosts);
  my-vpn-addr = ppfmisc.internalIP nodeData.hostNumber;
  subst-list = map (name: "http://${name}.vpn:${builtins.toString store-port}")
    all-nodes-except-me;
in {
  config = mkIf has-vpn {
    # Two things to configure, nix-serve and then using all other nodes
    sops.secrets.shared-store-key = {
      format = "binary";
      sopsFile = ../../keys/shared-store-key;
    };
    services.nix-serve = {
      enable = true;
      port = store-port;
      bindAddress = my-vpn-addr;
      secretKeyFile = config.sops.secrets.shared-store-key.path;
    };

    nix.settings = {
      substituters = subst-list;
      trusted-substituters = subst-list;
      trusted-public-keys = [ ppfmisc.store-public-key ];
    };

  };
}
