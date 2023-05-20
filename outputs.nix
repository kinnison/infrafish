{ self
, flake-utils
, nixpkgs
, sops-nix
, deploy
, ...
} @ inputs:
(
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages."${system}";
  in
  {
    devShell = pkgs.callPackage ./shell.nix {
      inherit (sops-nix.packages."${pkgs.system}") sops-import-keys-hook ssh-to-pgp sops-init-gpg-key;
      inherit (deploy.packages."${pkgs.system}") deploy-rs;
    };
  })) // {
    nixosConfigurations = import ./hosts/configurations.nix (inputs // {
      inherit inputs;
    });

    deploy = import ./hosts/deploy.nix (inputs // {
      inherit inputs;
    });

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy.lib;
}