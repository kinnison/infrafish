# Pepperfish NixOS setup

This repository contains all of the Pepperfish systems as Nix flakes

To use this you will need Nix configured to enable flakes.

Then you can run `nix devshell` and work from there.

# Adding a host

This is very very unlikely to be complete but I will update it as and
when I can to try and improve matters.

If the host is not already running nixos then you need to infect it
using nixos-infect. This is likely to work only if you have Debian 11
or newer.

Approximately:

1. Ensure root has an authorized_keys
2. infect with:
   ```console
   $ which curl || apt install -y curl
   $ copy in nixos-infect from wherever
   ... examine the downloaded script
   $ env NIX_CHANNEL=nixos-23.05 NO_REBOOT=1 doNetConf=y bash -x nixos-infect
   ```
   (you may not need doNetConf if the VM DHCPs)
3. Check the status of things like the bootloader, in case
4. Reboot your host and log back into it directly
5. Check and make any tweaks necessary, reboot, etc. once you're happy then we can proceed

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
then this might simply overwrite them, so be careful.

Finally you will need to create SSH keys for the root user which
can then be used to support backups etc. Do this with the aptly named
`tools/make-root-ssh` utility. It will put them into the right SOPS
file for you. As with the WG keys, this might overwrite so be careful.

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

## Basic configuration in hosts/$systemname

You need to get some basic configuration into hosts/$systemname - you can
begin by acquiring this from /etc/nixos on the system

Then you can go ahead and configure it how you want.

To deploy just one host you can do `deploy -i '.#systemname.system`
