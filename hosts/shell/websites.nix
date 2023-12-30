{ pkgs, config, lib, raw-users, ... }:
with lib;
let

  # Transform { dsilvers.websites = { "foo" = {..} }}
  # Into {"foo" = { user="dsilvers", .. }}

  augment-with-user = user: websites:
    builtins.mapAttrs (siteName: data:
      (data // {
        inherit user;
        ssl = if data ? ssl then data.ssl else true;
        logging = if data ? logging then data.logging else false;
        listings = if data ? listings then data.listings else false;
        extraNames = if data ? extraNames then data.extraNames else [];
        cgi = if data ? cgi then data.cgi else false;
      })) websites;

  all-websites = concatMapAttrs (user: data:
    if data ? websites then (augment-with-user user data.websites) else { })
    raw-users;

  socketName = name: conf: "/run/nginx/fcgiwrap-${conf.user}-${name}.sock";

  mkConfig = name: conf:
    let
      log_conf = if conf.logging then ''
        access_log /home/${conf.user}/websites/${name}/logs/access.log;
      '' else
        "";
      index_conf = if conf.listings then "autoindex on;" else "";
      rewrite_conf = if conf.extraNames != [] then ''
        if ($http_host != '${name}') {
          return 301 $scheme://${name}$request_uri;
        }
      '' else "";
      cgi_conf = if conf.cgi then ''
        location ~ .cgi$ {
          fastcgi_pass unix:${socketName name conf};
        }
      '' else "";
    in {
      root = "/home/${conf.user}/websites/${name}/html";
      forceSSL = conf.ssl;
      useACMEHost = mkIf conf.ssl name;
      extraConfig = ''
        ${log_conf}
        ${index_conf}
        ${rewrite_conf}
        ${cgi_conf}
      '';
      serverAliases = conf.extraNames;
    };

  ssl-sites = filterAttrs (n: d: d.ssl) all-websites;
  cgi-sites = filterAttrs (n: d: d.cgi) all-websites;

  mkService = name: conf: lib.nameValuePair ("fcgiwrap-${name}") {
    after = [ "nss-user-lookup.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.fcgiwrap}/sbin/fcgiwrap -c 1";
      User = conf.user;
      Group = conf.user;
      Environment = "PATH=/run/wrappers/bin:/home/${conf.user}/.nix-profile/bin:/nix/profile/bin:/home/${conf.user}/.local/state/nix/profile/bin:/etc/profiles/per-user/${conf.user}/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    };
  };

  mkSocket = name: conf: lib.nameValuePair ("fcgiwrap-${name}") {
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      ListenStream = socketName name conf;
      SocketUser = "nginx";
      SocketGroup = "nginx";
    };
  };

in {

  services.nginx.virtualHosts = builtins.mapAttrs mkConfig all-websites;

  security.acme.certs =
    builtins.mapAttrs (n: d: { group = config.services.nginx.group; extraDomainNames = d.extraNames; })
    ssl-sites;

  systemd.services = lib.mapAttrs' mkService cgi-sites;
  systemd.sockets = lib.mapAttrs' mkSocket cgi-sites;

}
