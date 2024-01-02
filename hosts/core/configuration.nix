# Utility system configuration
{ lib, config, pkgs, nodeData, hosts, ppfmisc, ... }:
with lib;
let
  systems = concatStrings (mapAttrsToList (n: d:
    let
      hostIP = ppfmisc.internalIP d.hostNumber;
      group = if d ? munin-group then d.munin-group else "infrafish";
    in ''
      [${group};${n}]
      address ${hostIP}

    '') hosts);
in {
  imports = [ ./hardware-configuration.nix ./networking.nix ];

  zramSwap.enable = true;

  pepperfish.munin-node.enable = true;

  # Utils is the munin server so let's configure that here
  services.munin-cron = {
    enable = true;
    hosts = systems;
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "munin.infrafish.uk" = {
        onlySSL = true;
        useACMEHost = "munin.infrafish.uk";
        root = "/var/www/munin";
      };
    };
    appendHttpConfig = ''
      ssl_session_cache shared:SSL:10m;
    '';
  };

  security.acme.certs = {
    "munin.infrafish.uk" = { group = config.services.nginx.group; };
  };

  services.postgresql = {
    enable = true;
    # At some point we need to upgrade to pg15
    package = pkgs.postgresql_14;
    settings.listen_addresses = mkOverride 50 "core.vpn";
    authentication = ''
      host all all ${ppfmisc.internalIP 1}/24 trust
    '';
  };

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    startAt = "*-*-* 02:15:00";
  };

  services.borgbackup.jobs.postgresql = {
    startAt = "*-*-* 03:00:00";
    paths = [ config.services.postgresqlBackup.location ];
    repo = (ppfmisc.borgURI nodeData.storage-user "postgresql");
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /run/secrets/backup-passphrase";
    };
    compression = "auto,lzma";
  };

  pepperfish.mailcore.enable = true;

  services.borgbackup.jobs.email = {
    startAt = "*-*-* 03:15:00";
    paths = [ "/var/spool/exim" "/var/mail" ];
    repo = (ppfmisc.borgURI nodeData.storage-user "email");
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /run/secrets/backup-passphrase";
    };
    compression = "auto,lzma";
  };

  services.redis.servers.rspamd = {
    enable = true;
    port = 6379;
    requirePassFile = config.sops.secrets.rspamd-redis-passphrase.path;
    bind = ppfmisc.internalIP nodeData.hostNumber;
  };

  sops.secrets.rspamd-redis-passphrase = {
    sopsFile = ../../keys/rspamd-redis-passphrase;
    format = "binary";
  };

  networking.firewall.allowedTCPPorts = [ 443 ];

  # environment.systemPackages = [ pkgs.local.dmarc-report-converter ];

  # So that the wireguard on core can route between endpoints
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

}
