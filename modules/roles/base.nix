# Pepperfish base role

{ config, pkgs, lib, ...}:

with lib;

{
  config = {
    time.timeZone = mkDefault "Europe/London";
    boot.cleanTmpDir = mkDefault true;
    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = "without-password";
    };
  };

  users.extraUsers.root.shell = mkOverride 50 "${pkgs.bashInteractive}/bin/bash";

  environment.systemPackages = with pkgs; [
    screen
    curl
    openssh
  ];
}