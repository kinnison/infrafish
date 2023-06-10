# Pepperfish NixOS network setup

## core

The core server is the VPN hub, the munin-cron, database server, etc.

## services0

The services boxes are DNS, Mail frontend, and various other shared services.

Note that the powerdns user, database, and schema had to be done by hand on the
core system before the DNS stuff could deploy successfully.
