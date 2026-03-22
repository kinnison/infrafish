{ pkgs, mailconfig, ... }:
with pkgs; {
  mailconfig = mailconfig.mailconfig;
  exim-core = exim.override {
    enablePgSQL = true;
    enableAuthDovecot = true;
    enableSRS = true;
  };
  # The additional overrideAttrs is there because we need write access to the spool
  exim-inmail = (exim.override {
    enableJSON = true;
    enableSRS = true;
  }).overrideAttrs {
    postPatch = ''
      sed -e "s/, 0750, /, 0770, /" src/spool_mbox.c > src/spool_mbox.sed && mv src/spool_mbox.sed src/spool_mbox.c
    '';
  };

  dmarc-report-converter = callPackage ./dmarc-report-converter.nix { };
}
