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

  networking.firewall.allowedTCPPorts = [ 53 443 80 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
