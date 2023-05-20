{ mkShell
, sops-import-keys-hook
, ssh-to-pgp
, sops-init-gpg-key
, sops
, deploy-rs
, nixpkgs-fmt
}:

mkShell {
  sopsPGPKeyDirs = [ "./keys/users" ];
  nativeBuildInputs = [
    ssh-to-pgp
    sops-import-keys-hook
    sops-init-gpg-key
    sops
    deploy-rs
    nixpkgs-fmt
  ];
}