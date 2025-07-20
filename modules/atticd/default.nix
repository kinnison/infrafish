{ config, lib, ... }:
let cfg = config.pepperfish.atticd;
in with lib; {
  options.pepperfish.atticd = { enable = mkEnableOption "Attic service"; };

  config = mkIf cfg.enable {
    security.acme.certs."attic.infrafish.uk" = {
      group = config.services.nginx.group;
      reloadServices = [ "nginx.service" ];
    };
    sops.secrets.atticd-envfile = {
      sopsFile = ../../keys/atticd-envfile;
      format = "binary";
      owner = config.services.atticd.user;
    };
    services.atticd = {
      enable = true;
      environmentFile = config.sops.secrets.atticd-envfile.path;
      settings = {
        listen = "127.0.0.1:17713";
        api-endpoint = "https://attic.infrafish.uk/";
        database = mkForce { };
        storage = {
          type = "s3";
          region = "hel1";
          bucket = "infrafish-attic";
          endpoint = "https://hel1.your-objectstorage.com";
          # Credentials are in the envfile
        };
      };
    };

    # For whatever reason, the atticd module doesn't create the
    # user and group, so we have to do so here
    users.users.${config.services.atticd.user} = {
      description = "Attic cache daemon for Nix derivations";
      group = config.services.atticd.group;
      isSystemUser = true;
    };
    users.groups.${config.services.atticd.group} = { };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "attic.infrafish.uk" = {
          onlySSL = true;
          useACMEHost = "attic.infrafish.uk";
          locations."/" = {
            proxyPass = "http://127.0.0.1:17713";
            extraConfig = ''
              client_max_body_size 2G;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
      };
    };
  };
}
