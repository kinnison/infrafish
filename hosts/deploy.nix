# Deploy instructions for Pepperfish hosts

{ self
, deploy
, ...
}:
let
  mkNode = server: ip: fast: {
    hostname = "${ip}:22";
    fastConnection = fast;
    profiles.system.path =
      deploy.lib.x86_64-linux.activate.nixos
        self.nixosConfigurations."${server}";
  };
in
{
  user = "root";
  sshUser = "root";
  nodes = {
    utils = mkNode "utils" "192.168.122.1" true;
  };
}