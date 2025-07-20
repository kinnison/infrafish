# Pepperfish NixOS setup

This repository contains all of the Pepperfish systems as Nix flakes

To use this you will need Nix configured to enable flakes.

Then you can run `nix devshell` and work from there.

# Accessing secrets

In the general case you do not need to be able to decrypt secrets
in order to use the tools here, however if you are creating new
or editing existing ones then you will need the primary key which
can be set up on your host by running `bash tools/decrypt-primary`

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

Next in order to support backing things up you will need to log into
the backup service and create a dir and user for the host.

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

You also **MUST** provide the backup details otherwise the host config
will not build successfully.

## How to set up the backup stuff

Firstly log into robot; then ssh as the main user on port 23 to the
backup box and `mkdir infrafish/$hostname`

Next, on the robot, find the storage box, and go to sub-account/create
Choose the right base directory, enable SSH and external access, and
put a sensible comment: "Infrafish $hostname backups" for example.

Make a note of the username and add it to `hosts.nix`.

Next, you want to copy in the right keys, to do this do:

`ssh-copy-id -p 23 -s $subuser@$storagebox`
then
`ssh-copy-id -p 23 -s -i keys/hosts/$hostname_root_ssh_key.pub $subuser@$storagebox`

The first will need the password displayed on the create page, the second
should work via the SSH key, if this all works then you're done for this part.

## Basic configuration in hosts/$systemname

You need to get some basic configuration into hosts/$systemname - you can
begin by acquiring this from /etc/nixos on the system

Then you can go ahead and configure it how you want.

Note that `deploy` will ssh with an IP address so you should probably
ensure you've acquired the keys for the new host this way first

To deploy just one host you can do `deploy -i '.#systemname.system`

If during deployment you get errors along the lines of:

"Activation script snippet 'setupSecrets' failed (1)"

Then you probably forgot to use sops to update the keys for things
like the acme-credentials which are used for everyone. Look at
`.sops.yaml` and decide what `updatekeys` you need to run.

After the first full deploy, you'll want to log in and reboot the
system, watching the console. If all looks good then you're clear
to treat your new system like any other infrafish system, though
you probably need to deploy the other systems to ensure they have
the new VPN details for the newly added system

If all is well you can ping the other VPN boxes
