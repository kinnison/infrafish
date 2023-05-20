# Host configurations

{ self
, inputs
, nixpkgs
, sops-nix
}:
let 
  nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;
  customModules = import ../modules/modules-list.nix;
  baseModules = [
    { _module.args.inputs = inputs; }
    {
      imports = [
        ({ pkgs, ... }: {
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          documentation.info.enable = false;
        })
        sops-nix.nixosModules.sops
      ];
    }
  ];
  defaultModules = baseModules ++ customModules;
in
{
  utils = nixosSystem {
    system = "x86_64-linux";
    modules = defaultModules ++ [
      ./utils/configuration.nix
    ];
  };
}