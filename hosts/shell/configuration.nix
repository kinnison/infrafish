{ pkgs, config, lib, ppfmisc, nodeData, ... }:
let

  raw-users = import ./users.nix;

  shellFor = data:
    let rawShell = if data ? shell then data.shell else "";

    in {
      "" = config.users.defaultUserShell;
      "bash" = pkgs.bashInteractive;
      "zsh" = pkgs.zsh;
    }."${rawShell}";

  homeDir = username: "/home/${username}";

  users = builtins.mapAttrs (userName: userData: {
    isNormalUser = true;
    description = userData.name;
    group = userName;
    home = homeDir userName;
    homeMode = "0755";
    createHome = true;
    openssh.authorizedKeys.keys = userData.defaultKeys;
    shell = lib.mkOverride 50 (shellFor userData);
  }) raw-users;

  groups = builtins.mapAttrs (userName: userData:
    {
      # Nothing yet
    }) raw-users;

  user-backups = lib.mapAttrs' (userName: userData: {
    name = "user-home-${userName}";
    value = {
      startAt = "*-*-* 00:00:00";
      paths = [ (homeDir userName) ];
      repo = (ppfmisc.borgURI nodeData.storage-user "user-home-${userName}");
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /run/secrets/backup-passphrase";
      };
      compression = "auto,lzma";
    };
  }) raw-users;

  user-backups-jitter = lib.mapAttrs' (userName: userData: {
    name = "borgbackup-job-user-home-${userName}";
    value = {
      timerConfig = {
        RandomizedDelaySec = 3600;
        FixedRandomDelay = true;
      };
    };
  }) raw-users;

  motdBanner = pkgs.writeText "motd-banner.txt" ''
     ___        __            __ _     _     
    |_ _|_ __  / _|_ __ __ _ / _(_)___| |__  
     | || '_ \| |_| '__/ _` | |_| / __| '_ \ 
     | || | | |  _| | | (_| |  _| \__ \ | | |
    |___|_| |_|_| |_|  \__,_|_| |_|___/_| |_|

    Mail config help can be found online at:
      https://github.com/kinnison/infrafish-mailconfig/blob/main/USING.md

  '';

  mailconfig-bin = pkgs.writeShellApplication {
    name = "mailconfig";

    runtimeInputs = with pkgs; [ httpie jq ];

    text = ''
      method=$(echo "$1" | tr "[:lower:]" "[:upper:]")
      shift
      uri="$1"
      shift
      https -A bearer -a "$(cat ~/.mailconfig.token)" "''${method}" "https://mail.infrafish.uk/api/''${uri}" "$@"
    '';
  };

in {
  _module.args = { inherit raw-users; };
  imports = [ ./hardware-configuration.nix ./networking.nix ./websites.nix ];

  zramSwap.enable = true;

  pepperfish.munin-node.enable = true;

  # All the imported users
  users.users = users;
  users.groups = groups;

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    vteIntegration = true;
  };

  services.borgbackup.jobs = user-backups;
  systemd.timers = user-backups-jitter;

  networking.firewall.allowedUDPPortRanges = [{
    from = 60000;
    to = 61000;
  }];

  networking.firewall.allowedTCPPorts = [ 443 80 ];

  programs.rust-motd = {
    enable = true;
    enableMotdInSSHD = true;
    settings = {
      banner = {
        color = "light_blue";
        command = "cat ${motdBanner}";
      };
      uptime.prefix = "Up";
      filesystems.root = "/";
      memory.swap_pos = "beside";
      fail2_ban.jails = [ "sshd" ];
      last_run = { };
    };
  };

  systemd.services.rust-motd.path = with pkgs; [ bash fail2ban ];

  services.nginx = {
    enable = true;
    resolver.addresses = [ "193.108.199.129" ];
    virtualHosts = {
      "shell.infrafish.uk" = {
        onlySSL = true;
        useACMEHost = "shell.infrafish.uk";
        locations."~ ^/~(.+?)(/.*)?$" = {
          alias = "/home/$1/public_html$2";
          index = "index.html index.htm";
          extraConfig = "autoindex on;";
        };
      };
      "autoconfig.infrafish.uk" = {
        serverAliases = [ "autoconfig.*" ];
        onlySSL = false;
        locations."~ .*" = {
          proxyPass = "https://mail.infrafish.uk/api/autoconfig/$http_host";
        };
      };
    };
    appendHttpConfig = ''
      ssl_session_cache shared:SSL:10m;
    '';
  };

  security.acme.certs = {
    "shell.infrafish.uk" = { group = config.services.nginx.group; };
  };

  systemd.services.nginx.serviceConfig = { ProtectHome = false; };

  environment.systemPackages = with pkgs; [
    httpie
    screen
    tmux
    tinyfugue
    neomutt
    mosh
    mailconfig-bin
  ];
}
