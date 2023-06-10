{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "193.108.199.129" "2a03:9800:0:54::2" ];
    defaultGateway = "188.246.206.1";
    defaultGateway6 = {
      address = "2a03:9800:10:1fd::1";
      interface = "ens2";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce true;
    interfaces = {
      ens2 = {
        ipv4.addresses = [{
          address = "188.246.206.160";
          prefixLength = 24;
        }];
        ipv6.addresses = [
          {
            address = "2a03:9800:10:1fd::2";
            prefixLength = 64;
          }
          {
            address = "fe80::5054:ff:fe25:e1e9";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [{
          address = "188.246.206.1";
          prefixLength = 32;
        }];
        ipv6.routes = [{
          address = "2a03:9800:10:1fd::1";
          prefixLength = 128;
        }];
      };

    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="52:54:00:25:e1:e9", NAME="ens2"

  '';
}
