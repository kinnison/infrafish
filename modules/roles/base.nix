# Pepperfish base role

{ config, pkgs, lib, nodeName, ppfmisc, ... }:

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
    networking.domain = "";

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

    system.stateVersion = "23.05";
  };
}
