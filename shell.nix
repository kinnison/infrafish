{ mkShell
, sops
, deploy-rs
, nixpkgs-fmt
, age
, ssh-to-age
}:

mkShell {
  nativeBuildInputs = [
    age
    ssh-to-age
    sops
    deploy-rs
    nixpkgs-fmt
  ];
}