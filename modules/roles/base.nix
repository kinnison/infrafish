# Pepperfish base role

{ config, pkgs, lib, nodeName, nodeData, ppfmisc, hosts, ... }:

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

    users.mutableUsers = false;
    users.users.root.shell = mkOverride 50 "${pkgs.bashInteractive}/bin/bash";
    users.users.root.openssh.authorizedKeys.keys = ppfmisc.rootPermittedKeys;

    sops.secrets.shared-fallback-root = {
      sopsFile = ../../keys/shared-fallback-root;
      format = "binary";
    };
    users.users.root.passwordFile =
      config.sops.secrets.shared-fallback-root.path;
    users.users.root.hashedPassword = null;

    environment.systemPackages = with pkgs; [
      screen
      curl
      openssh
      less
      vim
      swaks
      tmux
      jq
    ];

    services.fail2ban = {
      enable = true;
      jails.sshd = ''
        enabled = true
        port = 22
        mode = extra
      '';
    };

    services.ntp.enable = true;
    services.haveged.enable = true;
    programs.zsh.enable = true;

    services.fstrim.enable = true;

    boot.kernel.sysctl = {
      "net.ipv4.tcp_sack" = 0;
      "vm.overcommit_memory" = 1;
    };

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

    # Root's SSH key comes next
    sops.secrets.root-ssh-private = {
      format = "binary";
      sopsFile = ../../keys/hosts/${nodeName}_root_ssh_key;
    };

    fonts.fontconfig.enable = false;

    services.openssh.knownHosts = (builtins.mapAttrs (name: value: {
      publicKeyFile = ../../keys/hosts/${name}_ssh_host_ed25519_key.pub;
      extraHostNames = [
        "${name}.infrafish.uk"
        "${name}.vpn"
        (ppfmisc.internalIP value.hostNumber)
      ];
    }) hosts) // ppfmisc.extraHostKeys;

    sops.secrets.backup-passphrase = {
      format = "binary";
      sopsFile = ../../keys/backup-passphrase;
    };

    services.borgbackup.jobs.system-files = {
      startAt = "*-*-* 00:00:00";
      paths = [ "/var/lib/acme" ];
      repo = (ppfmisc.borgURI nodeData.storage-user "system");
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /run/secrets/backup-passphrase";
      };
      compression = "auto,lzma";
    };

    system.stateVersion = "23.05";
  };
}
