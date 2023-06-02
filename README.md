# Pepperfish NixOS setup

This repository contains all of the Pepperfish systems as Nix flakes

To use this you will need Nix configured to enable flakes.

Then you can run `nix devshell` and work from there.

# Adding a host

This is very very unlikely to be complete but I will update it as and
when I can to try and improve matters.

## Basic prep

Install a system somehow and get hold of keys by means of things like
`tools/fetch-ssh`.

Having done that, you will also want to add the host to .sops.yaml
and then `sops updatekeys keys/hosts/somehost_ssh_host_keys.yaml` so
that it can read things. You get the public keys from the file saved
by `fetch-ssh` (`keys/hosts/somehost.pub`).

Next you'll need to create wireguard keys, you can do this using the
`tools/make-wg-keys` utility. It will put them into the right SOPS
file for you. Note, if you run this when the host already has keys,
then this will simply overwrite them, so be careful.

## Required data in `hosts.nix`

The host must be present in the `hosts.nix` file. Each entry provides
information on how to deploy (IP/port) and then internal network id
etc.

Under the vpn attribute you also state the vpn core/lighthouse and
the public key for this host, providing you want it to be on the VPN.

The IP for a host on the VPN will be automatically set, and hosts
entries will be deployed to all hosts for all hosts on the same VPN.

Note, the VPN is only for connection between hosts, and does not grant
NAT or other access. Any support for such an additional VPN will be
in host specific configuration.
