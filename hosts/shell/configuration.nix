{ pkgs, config, lib, ... }:
let

  raw-users = import ./users.nix;

  shellFor = data:
    let rawShell = if data ? shell then data.shell else "";

    in {
      "" = config.users.defaultUserShell;
      "bash" = pkgs.bashInteractive;
      "zsh" = pkgs.zsh;
    }."${rawShell}";

  users = builtins.mapAttrs (userName: userData: {
    isNormalUser = true;
    description = userData.name;
    group = userName;
    home = "/home/${userName}";
    homeMode = "0755";
    createHome = true;
    openssh.authorizedKeys.keys = userData.defaultKeys;
    shell = lib.mkOverride 50 (shellFor userData);
  }) raw-users;

  groups = builtins.mapAttrs (userName: userData:
    {
      # Nothing yet
    }) raw-users;

in {
  imports = [ ./hardware-configuration.nix ./networking.nix ];

  zramSwap.enable = true;

  pepperfish.munin-node.enable = true;

  # All the imported users
  users.users = users;
  users.groups = groups;

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
    vteIntegration = true;
  };

}
