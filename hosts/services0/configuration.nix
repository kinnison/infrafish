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

  sops.secrets.rspamd-ui-password = {
    sopsFile = ../../keys/rspamd-ui-password;
    format = "binary";
    owner = "rspamd";
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
      default-soa-content=ns0.infrafish.uk hostmaster.@ 0 10800 3600 604800 3600
      resolver=127.0.0.1
      expand-alias=yes
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
      # This will have to change when we upgrade, possibly to a different admin interface
      # Since powerdns-admin is deprecated and pda-next has had no work in a year
      SESSION_TYPE = 'filesystem'
      SESSION_FILE_DIR='/run/powerdns-admin/flask-sessions'
      with open('${config.sops.secrets.pdns-admin-dburl.path}') as file:
          SQLALCHEMY_DATABASE_URI = file.read()
    '';
  };
  systemd.services.powerdns-admin.serviceConfig.BindReadOnlyPaths =
    [ config.sops.secrets.pdns-admin-dburl.path ];

  # This bypasses an issue with the powerdns-admin packaging
  # We don't set SESSION_TYPE so that we use the config above
  # Otherwise we can't run the migrate, so service setup fails
  systemd.services.powerdns-admin.serviceConfig.ExecStartPre = lib.mkForce
    "${pkgs.coreutils}/bin/env FLASK_APP=${pkgs.powerdns-admin}/share/powerdnsadmin/__init__.py ${pkgs.python3Packages.flask}/bin/flask db upgrade -d ${pkgs.powerdns-admin}/share/migrations";

  services.nginx = {
    enable = true;
    virtualHosts = {
      "pdns-admin.infrafish.uk" = {
        onlySSL = true;
        useACMEHost = "pdns-admin.infrafish.uk";
        locations."/" = { proxyPass = "http://127.0.0.1:8000"; };
      };
      "rspamui.infrafish.uk" = {
        onlySSL = true;
        useACMEHost = "rspamui.infrafish.uk";
        locations = {
          "/" = {
            root = "${pkgs.rspamd}/share/rspamd/www";
            tryFiles = "$uri @proxy";
          };
          "@proxy" = {
            proxyPass = "http://127.0.0.1:11334";
            extraConfig = ''
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header Host $host;
            '';
          };
        };
      };
    };
    appendHttpConfig = ''
      ssl_session_cache shared:SSL:10m;
    '';
  };

  security.acme.certs = {
    "pdns-admin.infrafish.uk" = { group = config.services.nginx.group; };
    "rspamui.infrafish.uk" = { group = config.services.nginx.group; };
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

  services.borgbackup.jobs.email = {
    startAt = "*-*-* 03:15:00";
    paths = [ "/var/spool/exim" ];
    repo = (ppfmisc.borgURI nodeData.storage-user "email");
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat /run/secrets/backup-passphrase";
    };
    compression = "auto,lzma";
  };

  services.rspamd.locals."worker-controller.inc".source =
    config.sops.secrets.rspamd-ui-password.path;

  environment.systemPackages = with pkgs; [ pdns ];
}
