{ pkgs, mailconfig, ... }:
with pkgs; {
  mailconfig = mailconfig.mailconfig;
  exim-core = exim.override {
    enablePgSQL = true;
    enableAuthDovecot = true;
    enableSRS = true;
  };
  exim-inmail = exim.override {
    enableJSON = true;
    enableSRS = true;
  };

  dmarc-report-converter = callPackage ./dmarc-report-converter.nix { };
}
