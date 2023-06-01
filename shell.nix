{ mkShell, sops, deploy-rs, nixpkgs-fmt, wireguard-tools, age, ssh-to-age }:

mkShell {
  nativeBuildInputs =
    [ age ssh-to-age sops deploy-rs nixpkgs-fmt wireguard-tools ];
}
