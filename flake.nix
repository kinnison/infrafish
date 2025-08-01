# Pepperfish NixOS flake top level

{
  description = "Pepperfish Systems";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    deploy.url = "github:serokell/deploy-rs";
    deploy.inputs.nixpkgs.follows = "nixpkgs";
    deploy.inputs.utils.follows = "flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mailconfig.url = "github:kinnison/infrafish-mailconfig";
    mailconfig.inputs.nixpkgs.follows = "nixpkgs";
    mailconfig.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { ... }@args:
    import ./outputs.nix (args // {
      hosts = import ./hosts.nix;
      ppfmisc = import ./misc.nix;
    });

  nixConfig = {
    extra-substituters = [ "https://attic.infrafish.uk/infrafish" ];
    extra-trusted-public-keys =
      [ "infrafish:D+tmoycePbBh+zjHC7Bawyc257pW6H3b8F+WvFoEFg0=" ];
  };
}
