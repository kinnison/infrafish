# Pepperfish base role

{ config, pkgs, lib, nodeName, ppfmisc, hosts, ... }:

with lib;

{
  config = {
    time.timeZone = mkDefault "Europe/London";
    boot.tmp.cleanOnBoot = mkDefault true;
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "without-password";
      };
    };

    networking.hostName = nodeName;
    networking.domain = "infrafish.uk";

    users.users.root.openssh.authorizedKeys.keys = ppfmisc.rootPermittedKeys;

    users.extraUsers.root.shell =
      mkOverride 50 "${pkgs.bashInteractive}/bin/bash";

    environment.systemPackages = with pkgs; [ screen curl openssh less vim ];

    services.fail2ban = {
      enable = true;

    };

    services.ntp.enable = true;
    services.haveged.enable = true;
    programs.zsh.enable = true;

    services.fstrim.enable = true;

    boot.kernel.sysctl = { "net.ipv4.tcp_sack" = 0; };

    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "dsilvers@digital-scurf.org";
        dnsProvider = "pdns";
        credentialsFile = config.sops.secrets.acme-credentials.path;
        dnsPropagationCheck = true;
      };
    };

    sops.secrets.acme-credentials = {
      format = "binary";
      sopsFile = ../../keys/acme-credentials;
    };

    system.stateVersion = "23.05";
  };
}
