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
      })) websites;

  all-websites = concatMapAttrs (user: data:
    if data ? websites then (augment-with-user user data.websites) else { })
    raw-users;

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
    in {
      root = "/home/${conf.user}/websites/${name}/html";
      forceSSL = conf.ssl;
      useACMEHost = mkIf conf.ssl name;
      extraConfig = ''
        ${log_conf}
        ${index_conf}
        ${rewrite_conf}
      '';
      serverAliases = conf.extraNames;
    };

  ssl-sites = filterAttrs (n: d: d.ssl) all-websites;

in {

  services.nginx.virtualHosts = builtins.mapAttrs mkConfig all-websites;

  security.acme.certs =
    builtins.mapAttrs (n: d: { group = config.services.nginx.group; extraDomainNames = d.extraNames; })
    ssl-sites;

}
