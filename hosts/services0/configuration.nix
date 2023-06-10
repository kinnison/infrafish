# Utility system configuration
{ lib, config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  zramSwap.enable = true;

  pepperfish.munin-node.enable = true;

}
