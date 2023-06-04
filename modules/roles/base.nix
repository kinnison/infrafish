# Pepperfish base role

{ config, pkgs, lib, nodeName, ... }:

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

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOgi5G6r/21IH5p0gDWQPomQPRcyGYtVK6D3uIl+A1QMvT6g9M6D+ecjvtQ8e1Rx5vGI2vgWxLN9fwIuoeWTRE9uRxD0fy6OHgSF95XY82OFC3RK1Bc3jLAVMP/BZUCqyXYbvgp6ggsc2fgEi+h+ZPG5bXwGgbwz0+vUJjMWZJKq0DVbKuVf41sOttBJ6FFZ7VbQ4t6qrq5HEnfXUPdCWtlfc+kDKwy+QLCB/xXBfkMzOsXrFfUdrx/80rWlaGa+0BuzHYst7xyP38KytEqHoz7txMv4HiLf2fkOcfpgIlFi+KPEcWfIUSgCKfC/7lyb2LHNec5IG/HYL59a2TCmIl cardno:5407828"
    ];

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
