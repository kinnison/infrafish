# Mail core
{ config, lib, pkgs, hosts, ppfmisc, ... }:
with lib;
let
  cfg = config.pepperfish.mailcore;

  coreip = ppfmisc.internalIP hosts.core.hostNumber;
  internalnet = "${ppfmisc.internalIP 0}/24";
  relay_ok_hosts = lib.concatStringsSep " ; "
    (lib.mapAttrsToList (n: d: ppfmisc.internalIP d.hostNumber)
      (lib.filterAttrs (n: d: d.mail ? relay-ok && d.mail.relay-ok) hosts));

  cert = config.security.acme.certs."mail.infrafish.uk";

  aclfile = builtins.readFile ./exim-acl;
  routerfile = builtins.readFile ./exim-router;
  transportfile = builtins.readFile ./exim-transport;

  detaintFile = pkgs.writeText "exim-detaint" ''
    *
  '';

  dodgySenderAllowList = pkgs.writeText "dodgy-sender-allowlist" ''
    *@*.mailjet.com
  '';

  eximConfig = ''

    # Bring in the secret settings
    .include ${config.sops.secrets.mailcore-exim-settings.path}
    .include ${config.sops.secrets.mail-exim-srs.path}

    MESSAGE_SIZE_LIMIT = 40M
    # The RFC defines this as 998 but Mailgun sometimes gives huge lines
    # This should be kept in-sync with mail-relay
    # Note, there is a risk here that this limit may cause us to get bounces
    # but it's a risk worth taking.
    MESSAGE_LINE_LENGTH_LIMIT = 2048
    DOVECOT_LDA = ${pkgs.dovecot}/libexec/dovecot/dovecot-lda

    DETAINTFILE = ${detaintFile}
    BADCHARS = \N[^A-Za-z0-9_.+-]+\N
    SAFESUFFIX = ''${lookup {''${sg{$local_part_suffix}{BADCHARS}{_}}} lsearch*,ret=key{DETAINTFILE}}

    DODGY_SENDER_ALLOWLIST = ${dodgySenderAllowList}

    primary_hostname = mail.infrafish.uk
    daemon_smtp_ports = 25 : 587 : 465
    local_interfaces = <; 127.0.0.1 ; ::1 ; ${coreip} ; ${hosts.core.ip}

    domainlist local_domains = ''${sg {''${lookup pgsql {select domainname from maildomain}{$value}}}{\n}{ : }}
    domainlist relay_to_domains =
    hostlist relay_from_hosts = <; 127.0.0.1 ; ::1 ; ${internalnet}
    hostlist unauthenticated_hosts = <; 127.0.0.1 ; ::1 ; ${relay_ok_hosts}

    tls_advertise_hosts = *
    tls_certificate = ${cert.directory}/fullchain.pem
    tls_privatekey = ${cert.directory}/key.pem

    tls_on_connect_ports = 465

    never_users = root

    smtp_banner           = "''${primary_hostname} ESMTP ''${tod_full}"
    host_lookup           = *
    allow_mx_to_ip        = true
    acl_smtp_connect      = ACL_slow_incoming
    acl_smtp_mail         = ACL_check_mail
    acl_smtp_rcpt         = ACL_check_rcpt
    acl_smtp_data         = ACL_check_data
    trusted_users              = root
    ignore_bounce_errors_after = 3h
    timeout_frozen_after       = 6h
    auto_thaw                  = 1h
    received_header_text  = "Received: \
         ''${if def:sender_rcvhost {from ''${sender_rcvhost}\n\t}\
         {''${if def:sender_ident {from ''${sender_ident} }}\
         ''${if def:sender_helo_name {(helo=''${sender_helo_name})\n\t}}}}\
         by ''${primary_hostname} \
         ''${if def:received_protocol {with ''${received_protocol}}} \
         (Exim ''${version_number} #''${compile_number} (Infrafish))\n\t\
         id ''${message_id}\
         ''${if def:received_for {\n\tfor <$received_for>}}"

    # Load management
    smtp_receive_timeout = 300s
    smtp_load_reserve = 15
    deliver_queue_load_max = 12
    queue_only_load = 15
    queue_run_max = 1
    smtp_accept_max = 50
    smtp_accept_max_per_host = 5
    smtp_reserve_hosts = ${internalnet} ; 127.0.0.1 ; ::1
    smtp_accept_reserve = 10

    dns_ipv4_lookup = *.google.com

    helo_allow_chars = _:

    #log_file_path=:syslog
    #syslog_timestamp=false
    #log_selector = +smtp_connection +smtp_incomplete_transaction +smtp_no_mail +smtp_mailauth +smtp_protocol_error

    # Environment purge
    keep_environment =

    # For simplicity for now, disable IPv6 because many hosts cock it up
    disable_ipv6 = true

    begin acl

    ${aclfile}

    begin routers

    ${routerfile}

    begin transports

    ${transportfile}

    begin retry

    *                      *           F,2h,15m; G,16h,2h,1.5; F,4d,6h; F,14d,1d

    begin rewrite

    begin authenticators

    # Eventually add dovecot auth in here?

    dovecot_plain:
      driver = dovecot
      public_name = PLAIN
      server_socket = /run/dovecot2/auth-userdb-exim
      server_set_id = $auth1

    dovecot_login:
      driver = dovecot
      public_name = LOGIN
      server_socket = /run/dovecot2/auth-userdb-exim
      server_set_id = $auth1


  '';

  dovecotConfig = ''
    # Extra Dovecot config

    passdb {
      driver = sql
      args = ${config.sops.secrets.mailcore-dovecot-sql-conf.path}
    }

    userdb {
      driver = sql
      args = ${config.sops.secrets.mailcore-dovecot-sql-conf.path}
    }

    service auth {
      unix_listener auth-userdb-exim {
        user = exim
        mode = 0600
      }
    }

    protocol lda {
      mail_plugins = $mail_plugins sieve
    }

  '';

in {
  options.pepperfish.mailcore = with types; {
    enable = mkEnableOption "enable the mail core on this host";

    mailconfig-package = mkOption {
      type = package;
      default = pkgs.local.mailconfig;
      defaultText = literalExpression "pkgs.local.vaultwarden";
      description = lib.mdDoc "Mailconfig package to use.";
    };
  };

  config = mkIf cfg.enable {

    users.groups.mailcert = {
      members = [ config.services.exim.user config.services.nginx.user ];
    };

    security.acme.certs."mail.infrafish.uk" = {
      group = "mailcert";
      reloadServices = [ "exim.service" "dovecot2.service" ];
    };

    sops.secrets.mailcore-mailconfig-env = {
      sopsFile = ../../keys/mailcore-mailconfig-env;
      format = "binary";
    };

    sops.secrets.mailcore-exim-settings = {
      sopsFile = ../../keys/mailcore-exim-settings;
      format = "binary";
      owner = config.services.exim.user;
    };

    sops.secrets.mailcore-dovecot-sql-conf = {
      sopsFile = ../../keys/mailcore-dovecot-sql-conf;
      format = "binary";
    };

    sops.secrets.mail-exim-srs = {
      sopsFile = ../../keys/mail-exim-srs;
      format = "binary";
    };

    services.exim = {
      enable = true;
      package = pkgs.local.exim-core;
      config = eximConfig;
    };

    networking.firewall.allowedTCPPorts = [ 465 587 993 995 4190 ];

    systemd.services.mailcore-mailconfig = {
      enable = true;
      after = [ "network.target" ];
      serviceConfig = {
        User = config.services.exim.user;
        Group = config.services.exim.group;
        EnvironmentFile = config.sops.secrets.mailcore-mailconfig-env.path;
        ExecStart = "${cfg.mailconfig-package}/bin/mailconfig";
        PrivateTmp = "true";
        PrivateDevices = "true";
        ProtectHome = "true";
        ProtectSystem = "strict";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        StateDirectory = "mailconfig";
        StateDirectoryMode = "0700";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
    };

    users.users.mail = {
      description = "Virtual Mail User";
      isSystemUser = true;
      group = "mail";
      home = "/var/mail";
      createHome = true;
    };

    users.groups.mail = { };

    services.dovecot2 = {
      enable = true;
      enablePop3 = true;
      enableImap = true;
      mailUser = "mail";
      mailGroup = "mail";
      createMailUser = false;
      modules = [ pkgs.dovecot_pigeonhole ];
      sslServerCert = "${
          config.security.acme.certs."mail.infrafish.uk".directory
        }/fullchain.pem";
      sslServerKey =
        "${config.security.acme.certs."mail.infrafish.uk".directory}/key.pem";
      extraConfig = dovecotConfig;
      enablePAM = false;
      mailLocation = "maildir:~/Maildir";
      protocols = [ "sieve " ];
      sieve = { extensions = [ "imapflags" ]; };
    };

    sops.secrets.mailcore-roundcube-password = {
      sopsFile = ../../keys/mailcore-roundcube-password;
      format = "binary";
    };

    services.roundcube = {
      enable = true;
      database = {
        host = "core.vpn";
        dbname = "roundcube";
        username = "roundcube";
        passwordFile = config.sops.secrets.mailcore-roundcube-password.path;
      };
      hostName = "mail.infrafish.uk";
      maxAttachmentSize = 10;
      dicts = with pkgs.aspellDicts; [ en ];
      package = pkgs.roundcube.withPlugins (plugins:
        with plugins; [
          persistent_login
          carddav
          custom_from
          contextmenu
          thunderbird_labels
        ]);
      plugins = [
        "additional_message_headers"
        "attachment_reminder"
        "carddav"
        "contextmenu"
        "custom_from"
        "emoticons"
        "managesieve"
        "newmail_notifier"
        "persistent_login"
        "show_additional_headers"
        "thunderbird_labels"
        "userinfo"
        "vcard_attachments"
        "zipdownload"
      ];
    };

    # Roundcube has a setup service which needs to run, but it depends on postgresql
    # which is a service we're running on the same box; so let's depend on it in
    # the systemd unit
    systemd.services.roundcube-setup = { after = [ "postgresql.service" ]; };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "mail.infrafish.uk" = {
          onlySSL = true;
          forceSSL = false;
          enableACME = false;
          useACMEHost = "mail.infrafish.uk";
          locations."/api" = { proxyPass = "http://127.0.0.1:1537/api"; };
        };
      };
    };

    services.fail2ban = {
      enable = true;
      jails = {
        exim.settings = {
          enabled = true;
          journalmatch = "_SYSTEMD_UNIT=exim.service";
          port = "465,587";
        };
        dovecot.settings = {
          enabled = true;
          port = "993,995,4190";
        };
      };
    };

    environment.etc = {
      "fail2ban/filter.d/exim-common.local" = {
        text = ''
          [Definition]
          pid = (?: \[\d+\]|\S?\w+ exim\[\d+\]:)? \S+ \S+
        '';
      };
    };

  };
}
