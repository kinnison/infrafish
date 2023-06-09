# Miscellaneous configuration for Peppernix
let
  danielSSHKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOgi5G6r/21IH5p0gDWQPomQPRcyGYtVK6D3uIl+A1QMvT6g9M6D+ecjvtQ8e1Rx5vGI2vgWxLN9fwIuoeWTRE9uRxD0fy6OHgSF95XY82OFC3RK1Bc3jLAVMP/BZUCqyXYbvgp6ggsc2fgEi+h+ZPG5bXwGgbwz0+vUJjMWZJKq0DVbKuVf41sOttBJ6FFZ7VbQ4t6qrq5HEnfXUPdCWtlfc+kDKwy+QLCB/xXBfkMzOsXrFfUdrx/80rWlaGa+0BuzHYst7xyP38KytEqHoz7txMv4HiLf2fkOcfpgIlFi+KPEcWfIUSgCKfC/7lyb2LHNec5IG/HYL59a2TCmIl cardno:5407828";
  rauhaKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHJQNkNYNGj+O//LldKl9wSjIrrtgI79nIArijEGNRgM danielsilverstone@rauha";
  storageServer = "u356603.your-storagebox.de";
  storageServerHostKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  storageServerHostKey23 =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
in {
  internalIP = hostNumber: "10.105.102.${builtins.toString hostNumber}";
  munin-core = "core";
  rootPermittedKeys = [ danielSSHKey rauhaKey ];
  primary-ns = "services0";
  inherit storageServer;
  borgURI = username: repo:
    "ssh://${username}@${storageServer}:23/./borg-${repo}";
  extraHostKeys = {
    "${storageServer}".publicKey = storageServerHostKey;
    "[${storageServer}]:23".publicKey = storageServerHostKey23;
  };
}
