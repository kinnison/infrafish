# Host configurations

{ self, inputs, nixpkgs, sops-nix, home-manager, hosts, ppfmisc, mailconfig, ...
}:
let
  nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;
  customModules = import ../modules/modules-list.nix;
  overlays = [
    (final: prev: {
      local = import ../pkgs {
        mailconfig = mailconfig.packages.${prev.system};
        pkgs = prev;
      };
      dovecot = prev.dovecot.override { withPgSQL = true; };
    })
  ];
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
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.root = import ../modules/roles/root.nix;
          home-manager.extraSpecialArgs = {
            inherit hosts;
            inherit ppfmisc;
          };
        }
      ];
      nixpkgs.overlays = overlays;
    }
  ];
  defaultModules = baseModules ++ customModules;

  mkSystem = nodename: data:
    nixosSystem {
      system = if data ? system then data.system else "x86_64-linux";
      modules = defaultModules ++ [
        {
          _module.args = {
            nodeData = data;
            nodeName = nodename;
            inherit hosts;
            inherit ppfmisc;
          };
        }
        ./${nodename}/configuration.nix
      ];
    };
in builtins.mapAttrs mkSystem hosts
