# Deploy instructions for Pepperfish hosts

{ self, deploy, hosts, ... }:
let
  mkNode = server: ip: port: fast: {
    hostname = "${ip}";
    sshOpts = [ "-p" "${builtins.toString port}" ];
    fastConnection = fast;
    profiles.system.path = deploy.lib.x86_64-linux.activate.nixos
      self.nixosConfigurations."${server}";
  };
in {
  user = "root";
  sshUser = "root";
  nodes =
    builtins.mapAttrs (nodename: data: mkNode nodename data.ip data.port false)
    hosts;
}
