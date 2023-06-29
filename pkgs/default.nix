{pkgs, ...}:
with pkgs;
{
  exim-core = callPackage ./exim.nix { enablePgSQL = true; };
  exim-inmail = callPackage ./exim.nix { enableJSON = true; enableSqlite = true; };
}
