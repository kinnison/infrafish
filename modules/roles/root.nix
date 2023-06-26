# This is the root user's home-manager setup, it is not expected to be super-clever

{ pkgs, lib, osConfig, hosts, ppfmisc, ... }: {

  home.activation = {
    myActivationAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG /root/.ssh
      $DRY_RUN_CMD chmod $VERBOSE_ARG 0700 /root/.ssh
      $DRY_RUN_CMD cp $VERBOSE_ARG /run/secrets/root-ssh-private /root/.ssh/id_ed25519
    '';
  };

  home.file.".ssh/id_ed25519.pub" = {
    source = ../../keys/hosts/${osConfig.networking.hostName}_root_ssh_key.pub;
  };

  home.file.".ssh/authorized_keys" = {
    text = with lib;
      concatStrings (mapAttrsToList (name: data:
        let
          hostKey = builtins.readFile ../../keys/hosts/${name}_root_ssh_key.pub;
        in ''
          # Root on ${name}
          ${hostKey}
        '') hosts);
  };

  home.stateVersion = "23.05";
}
