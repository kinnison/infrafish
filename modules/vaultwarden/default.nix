# Vaultwarden configuration for Pepperfish
{ config, lib, ... }:

with lib;

let cfg = config.pepperfish.vaultwarden;
in {
  options.pepperfish.vaultwarden = {
    enable = mkEnableOption "enable vaultwarden on this host";
  };

  config = mkIf (cfg.enable) {
    sops.secrets.vaultwarden-env = {
      sopsFile = ../../keys/vaultwarden-env;
      format = "binary";
    };
    services.vaultwarden = {
      enable = true;
      environmentFile = config.sops.secrets.vaultwarden-env.path;
      dbBackend = "sqlite";
      config = {
        domain = "https://vault.infrafish.uk";
        signupsAllowed = false;
        rocketAddress = "127.0.0.1";
        rocketPort = 8222;
        rocketLog = "critical";
        websocketEnabled = true;
        websocketAddress = "127.0.0.1";
        websocketPort = 8223;
        smtpHost = "core.vpn";
        smtpFrom = "vaultwarden@infrafish.uk";
        smtpAcceptInvalidCerts =
          true; # the cert used is mail.infrafish.uk but we need to use core.vpn for forwarding
      };
      backupDir = "/var/lib/bitwarden_rs/backups";
    };

    security.acme.certs = {
      "vault.infrafish.uk" = { group = config.services.nginx.group; };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "vault.infrafish.uk" = {
          onlySSL = true;
          useACMEHost = "vault.infrafish.uk";
          locations."/" = {
            proxyPass = "http://127.0.0.1:8222";
            proxyWebsockets = true;
          };
          locations."/notifications/hub" = {
            proxyPass = "http://127.0.0.1:8223";
            proxyWebsockets = true;
          };
          locations."/notifications/hub/negotiate" = {
            proxyPass = "http://127.0.0.1:8222";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
