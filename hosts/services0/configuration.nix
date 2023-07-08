# Utility system configuration
{ lib, config, pkgs, ppfmisc, nodeData, ... }:

{
  imports = [ ./hardware-configuration.nix ./networking.nix ];

  zramSwap.enable = true;

  pepperfish.munin-node.enable = true;

  sops.secrets.pdns-secrets = {
    sopsFile = ../../keys/pdns-secrets;
    format = "binary";
  };

  services.powerdns = {
    enable = true;
    extraConfig = ''
      launch=gpgsql
      gpgsql-host=core.vpn
      gpgsql-dbname=pdns
      gpgsql-user=pdns
      gpgsql-password=$PDNSDBPASSWORD
      gpgsql-dnssec=yes
      webserver=yes
      webserver-address=${ppfmisc.internalIP nodeData.hostNumber}
      webserver-password=$PDNSWEBPASSWORD
      webserver-allow-from=${ppfmisc.internalIP nodeData.hostNumber}/24
      api=yes
      api-key=$PDNSWEBPASSWORD
    '';
    secretFile = config.sops.secrets.pdns-secrets.path;
  };

  sops.secrets.pdns-admin-salt = {
    sopsFile = ../../keys/pdns-admin.yaml;
    owner = "powerdnsadmin";
  };

  sops.secrets.pdns-admin-secret = {
    sopsFile = ../../keys/pdns-admin.yaml;
    owner = "powerdnsadmin";
  };

  sops.secrets.pdns-admin-dburl = {
    sopsFile = ../../keys/pdns-admin.yaml;
    owner = "powerdnsadmin";
  };

  services.powerdns-admin = {
    enable = true;
    secretKeyFile = config.sops.secrets.pdns-admin-secret.path;
    saltFile = config.sops.secrets.pdns-admin-salt.path;
    config = ''
      BIND_ADDRESS = '127.0.0.1'
      SESSION_TYPE = 'sqlalchemy'
      with open('${config.sops.secrets.pdns-admin-dburl.path}') as file:
          SQLALCHEMY_DATABASE_URI = file.read()
    '';
  };
  systemd.services.powerdns-admin.serviceConfig.BindReadOnlyPaths =
    [ config.sops.secrets.pdns-admin-dburl.path ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "pdns-admin.infrafish.uk" = {
        onlySSL = true;
        useACMEHost = "pdns-admin.infrafish.uk";
        locations."/" = { proxyPass = "http://127.0.0.1:8000"; };
      };
    };
  };

  security.acme.certs = {
    "pdns-admin.infrafish.uk" = { group = config.services.nginx.group; };
  };

  pepperfish.vaultwarden.enable = true;

  services.borgbackup.jobs.vaultwarden = {
    startAt = "*-*-* 04:00:00";
    paths = [ config.services.vaultwarden.backupDir ];
    repo = (ppfmisc.borgURI nodeData.storage-user "vaultwarden");
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /run/secrets/backup-passphrase";
    };
    compression = "auto,lzma";
  };

  networking.firewall.allowedTCPPorts = [ 53 443 80 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  pepperfish.mail-frontend.enable = true;

  environment.systemPackages = with pkgs; [ pdns strace ];
}
