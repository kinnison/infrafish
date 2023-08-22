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

in {
  imports = [ ./hardware-configuration.nix ./networking.nix ];

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

  environment.systemPackages = with pkgs; [
    httpie
    screen
    tmux
    tinyfugue
    neomutt
    mosh
  ];
}
