# Miscellaneous configuration for Peppernix
let
  danielSSHKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOgi5G6r/21IH5p0gDWQPomQPRcyGYtVK6D3uIl+A1QMvT6g9M6D+ecjvtQ8e1Rx5vGI2vgWxLN9fwIuoeWTRE9uRxD0fy6OHgSF95XY82OFC3RK1Bc3jLAVMP/BZUCqyXYbvgp6ggsc2fgEi+h+ZPG5bXwGgbwz0+vUJjMWZJKq0DVbKuVf41sOttBJ6FFZ7VbQ4t6qrq5HEnfXUPdCWtlfc+kDKwy+QLCB/xXBfkMzOsXrFfUdrx/80rWlaGa+0BuzHYst7xyP38KytEqHoz7txMv4HiLf2fkOcfpgIlFi+KPEcWfIUSgCKfC/7lyb2LHNec5IG/HYL59a2TCmIl cardno:5407828";
  rauhaKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJQNkNYNGj+O//LldKl9wSjIrrtgI79nIArijEGNRgM danielsilverstone@rauha";
  danielShellKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAatCszLRng2E9q0a8rSVwK5ZZlADJtKCfv3tDFlNISX dsilvers@shell";
  robShellKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0zrxWAJyiHxqrCamlYeKbTxwLtQdSDR91GgaBp5KW+T/2jgUFUympyo+10nWcogEbYp6cJ+aFBCCt57eud6ivHCuXwBc2gKtoBv6vp/MRCTeRGpGh8gGKP6Muwrxio8zMEMOtBuG6sz87BFY0JZQ2Ge78Fub5BRrn/MRtAFjpReYp8gOZU09PXs5T7YOT2kPogrq62RXzafL49WeBkHA5EoI1qdOJPm4V5A1NlxE3BoXVLPaCUHcZMA4ZCLzkBvE0vttBgFULuC7QE1QvJBDFKLUQn+oA63iTBjhfp6x37+s/Y20FI324urpZwV28ZlJFGQNS8o2LKixsGEXLnhn/ rjek@platypus";
  storageServer = "u356603.your-storagebox.de";
  storageServerHostKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  storageServerHostKey23 =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
in {
  internalIP = hostNumber: "10.105.102.${builtins.toString hostNumber}";
  uservpnIP = hostNumber: "10.105.103.${builtins.toString hostNumber}";
  munin-core = "core";
  rootPermittedKeys = [ danielSSHKey rauhaKey danielShellKey robShellKey ];
  primary-ns = "services0";
  inherit storageServer;
  borgURI = username: repo:
    "ssh://${username}@${storageServer}:23/./borg-${repo}";
  extraHostKeys = {
    "${storageServer}".publicKey = storageServerHostKey;
    "[${storageServer}]:23".publicKey = storageServerHostKey23;
  };

  user-vpn = {
    root = {
      name = "shell";
      pubkey = "syfTfFBXHlAD3OdHxc6RdJUwDP6EMxCrITVwLRWFokA=";
      nodeNumber = 1;
    };
    hosts = [
      {
        name = "mobile";
        nodeNumber = 2;
        pubkey = "R4u1+TG2y45bZZeeDQH+ELOjYb/ZxJiADBfv3EGr01A=";
      }
      {
        name = "cataplexy";
        nodeNumber = 3;
        pubkey = "Prc1AWSusVWqovEvGVqmwN3kCTAa5wixCj4JSrlJZS0=";
      }
      {
        name = "kyllikki-mail";
        nodeNumber = 4;
        pubkey = "WUGWUqKlOLTvpGAETyYvtvwFMwN+UFKZZ7J1RbloRQA=";
      }
      {
        name = "edgar";
        nodeNumber = 5;
        pubkey = "I27ceGwaVpsgIuTSg8oeqAIJOJih59SACc0GGW3+mlU=";
      }
    ];

  };

  store-public-key =
    "infrafish.vpn-1:RTv8dMmNefaBEH41vdEJX+DIDtXEwBwUQ2atHcc0Koo=%";
}
