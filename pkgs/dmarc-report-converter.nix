{ pkgs, buildGoModule, fetchFromGitHub, ... }:
with pkgs;
buildGoModule rec {
  pname = "dmarc-report-converter";
  version = "0.6.5";
  src = fetchFromGitHub {
    owner = "tierpod";
    repo = "dmarc-report-converter";
    rev = "v${version}";
    sha256 = "sha256-4rAQhZmqYldilCKomBfuyqS0vcUg5yS4nqp84XSjam4=";
  };

  vendorSha256 = null;

  meta = with lib; {
    description = "DMARC report converter, written in Go";
    homepage = "https://github.com/tierpod/dmarc-report-converter";
    license = licenses.mit;
    #maintainers = with maintainers; [ kinnison ];
  };

}
