{pkgs, ...}:
with pkgs;
{
  exim = callPackage ./exim.nix { enablePgSQL = true; };
}
