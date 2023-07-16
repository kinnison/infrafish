{ pkgs, mailconfig, ... }:
with pkgs; {
  mailconfig = mailconfig.mailconfig;
  exim-core = callPackage ./exim.nix {
    enablePgSQL = true;
    enableAuthDovecot = true;
    enableSRS = true;
  };
  exim-inmail = callPackage ./exim.nix {
    enableJSON = true;
    enableSRS = true;
  };
}
