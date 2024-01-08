# Mail core
{ config, lib, pkgs, hosts, ppfmisc, nodeData, ... }:
with lib;
let
  cfg = config.pepperfish.mail-frontend;

  my-vpn-ip = ppfmisc.internalIP nodeData.hostNumber;
  my-real-ip = nodeData.ip;

  internalnet = "${ppfmisc.internalIP 0}/24";
  coreip = ppfmisc.internalIP hosts.core.hostNumber;

  cert = config.security.acme.certs."mx.infrafish.uk";

  exim-acl = builtins.readFile ./exim-acl;
  exim-router = builtins.readFile ./exim-router;
  exim-transport = builtins.readFile ./exim-transport;

  eximConfig = ''

    # Bring in the secret settings

    MESSAGE_SIZE_LIMIT = 40M

    primary_hostname = mx.infrafish.uk
    daemon_smtp_ports = 25 : 587 : 465
    local_interfaces = <; 127.0.0.1 ; ::1 ; ${my-vpn-ip} ; ${my-real-ip}

    CONF = /var/spool/exim/config
    JSON = CONF/conf.json
    GLOBAL = /etc/exim
    CORE_IP = ${coreip}

    domainlist local_domains = 
    domainlist relay_to_domains = ''${lookup {all_domains} json {JSON}}
    domainlist secondary_domains = 

    av_scanner = clamd:/run/clamav/clamd.ctl
    spamd_address = /run/rspamd/proxy.sock variant=rspamd

    tls_advertise_hosts = *
    tls_certificate = ${cert.directory}/fullchain.pem
    tls_privatekey = ${cert.directory}/key.pem

    tls_on_connect_ports = 465

    never_users = root

    smtp_banner           = "''${primary_hostname} ESMTP ''${tod_full}"
    host_lookup           = *
    allow_mx_to_ip        = true
    acl_smtp_helo         = ACL_check_helo
    acl_smtp_mail         = ACL_check_mail
    acl_smtp_rcpt         = ACL_check_rcpt
    #acl_smtp_mime         = ACL_check_mime
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
         ''${if def:sender_address \
           {(envelope-from <$sender_address>)\n\t}}\
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

    # Bits stolen from Debian
    CHECK_RCPT_REMOTE_LOCALPARTS = ^[./|] : ^.*[@%!`#&?] : ^.*/\\.\\./

    # DMARC setup
    dmarc_tld_file = ${./psl.dat}

    # For simplicity for now, disable IPv6 because many hosts cock it up
    disable_ipv6 = true

    begin acl

    ${exim-acl}

    begin routers

    ${exim-router}

    begin transports

    ${exim-transport}

    begin retry

    *                      *           F,2h,15m; G,16h,2h,1.5; F,4d,6h; F,14d,1d

    begin rewrite

    begin authenticators

  '';

  acquire-config-sh = ''
    #!/bin/sh

    BASE=$(mktemp -d -p /var/spool/exim)

    curl -s https://mail.infrafish.uk/api/frontend/json > "''${BASE}/conf.json"

    CONFHASH=$(sha1sum "''${BASE}/conf.json" | cut -f1 -d' ')
    OLDCONFHASH=$(readlink /var/spool/exim/config || echo "NOT-FOUND")

    if [ "x$OLDCONFHASH" = "x$CONFHASH" ]; then
      rm -rf "$BASE"
      exit 0
    fi

    for DOMAIN in $(jq -r '.per_domain | keys []' "''${BASE}/conf.json"); do
      jq -r '.per_domain["'"$DOMAIN"'"].sender_allow_list[]' "''${BASE}/conf.json" > "''${BASE}/sender_allow_list_''${DOMAIN}"
      jq -r '.per_domain["'"$DOMAIN"'"].sender_deny_list[]' "''${BASE}/conf.json" > "''${BASE}/sender_deny_list_''${DOMAIN}"
    done

    mv "$BASE" "/var/spool/exim/$CONFHASH"

    ln -nsf "$CONFHASH" /var/spool/exim/config

    rm -rf "/var/spool/exim/$OLDCONFHASH"

    echo "Replaced config $OLDCONFHASH with $CONFHASH"
  '';

in {
  options.pepperfish.mail-frontend = with types; {
    enable = mkEnableOption "enable the mail frontend on this host";
  };

  config = mkIf cfg.enable {

    security.acme.certs."mx.infrafish.uk" = {
      group = config.services.exim.group;
      reloadServices = [ "exim.service" ];
    };

    services.exim = {
      enable = true;
      package = pkgs.local.exim-inmail;
      config = eximConfig;
    };

    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
    };

    services.rspamd = {
      enable = true;
      workers = {
        normal = { };
        controller = { };
        rspamd_proxy = {
          extraConfig = ''
            milter = no;

            upstream "scan" {
              default = yes;
              hosts = "localhost:11334";
              compression = yes;
            }
          '';
        };
      };
      locals = {
        "redis.conf" = {
          enable = true;
          text = ''
            servers = "${ppfmisc.internalIP hosts.core.hostNumber}:6379";
            password = {= env.REDIS_PASSWORD =};
          '';
        };
        "classifier-bayes.conf" = {
          enable = true;
          text = ''
            per_user = <<EOD
            return function(task)
              local rcpt = task:get_recipients(1)

              if rcpt then
                one_rcpt = rcpt[1]
                if one_rcpt['domain'] then
                  return one_rcpt['domain']
                end
              end

              return nil
            end
            EOD
            autolearn {
              spam_threshold = 7.5;
              ham_threshold = -0.5;
              check_balance = true;
              min_balance = 0.9;
            }
          '';
        };
        "spamassassin.conf" = {
          enable = true;
          text = ''
            ruleset = [
              "${./sa-rules/ppf.cf}";
            ]
          '';
        };
      };
    };

    systemd.services.rspamd.serviceConfig.EnvironmentFile =
      config.sops.secrets.rspamd-redis-environment.path;

    sops.secrets.rspamd-redis-environment = {
      sopsFile = ../../keys/rspamd-redis-environment;
      format = "binary";
    };

    users.groups.clamav.members = [ config.services.exim.user ];
    users.groups.${config.services.exim.group}.members =
      [ config.services.clamav.daemon.settings.User ];
    users.groups.${config.services.rspamd.group}.members =
      [ config.services.exim.user ];

    networking.firewall.allowedTCPPorts = [ 25 465 587 ];

    systemd.services.mail-frontend-acquire-config = {
      enable = true;
      description = "Acquire mail frontend config";
      path = with pkgs; [ jq curl ];
      serviceConfig = {
        User = config.services.exim.user;
        Group = config.services.exim.group;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/var/spool/exim" ];
        PrivateTmp = true;
      };
      script = acquire-config-sh;
    };

    systemd.timers.mail-frontend-acquire-config = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = { OnCalendar = "minutely"; };
    };

    environment.etc = {
      "exim/local-helo-blacklist" = {
        enable = true;
        source = ./local-helo-blacklist;
      };
      "exim/sender-deny-list" = {
        enable = true;
        source = ./sender-deny-list;
      };
      "exim/sender-allow-list" = {
        enable = true;
        source = ./sender-allow-list;
      };
      "exim/host-local-deny-exceptions" = {
        enable = true;
        text = "spring-chicken-at.twitter.com";
      };
      "exim/sender-local-deny-exceptions" = {
        enable = true;
        text = ''
          MAILER-DAEMON (Mail Delivery System)
          MAILER-DAEMON
        '';
      };
      "exim/default-ip-dnsbl" = {
        enable = true;
        text = ''
          sbl-xbl.spamhaus.org
        '';
      };
      "exim/default-domain-dnsbl" = {
        enable = true;
        text = ''
          dbl.spamhaus.org
          mailsl.dnsbl.rjek.com
        '';
      };
      "exim/ignore-sender-verify-addresses" = {
        enable = true;
        source = ./ignore-sender-verify-addresses;
      };
    };

    services.fail2ban = {
      enable = true;
      jails = {
        exim.settings = {
          enabled = true;
          journalmatch = "_SYSTEMD_UNIT=exim.service";
          port = "25,465,587";
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
