# Miscellaneous configuration for Peppernix
let
  danielSSHKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOgi5G6r/21IH5p0gDWQPomQPRcyGYtVK6D3uIl+A1QMvT6g9M6D+ecjvtQ8e1Rx5vGI2vgWxLN9fwIuoeWTRE9uRxD0fy6OHgSF95XY82OFC3RK1Bc3jLAVMP/BZUCqyXYbvgp6ggsc2fgEi+h+ZPG5bXwGgbwz0+vUJjMWZJKq0DVbKuVf41sOttBJ6FFZ7VbQ4t6qrq5HEnfXUPdCWtlfc+kDKwy+QLCB/xXBfkMzOsXrFfUdrx/80rWlaGa+0BuzHYst7xyP38KytEqHoz7txMv4HiLf2fkOcfpgIlFi+KPEcWfIUSgCKfC/7lyb2LHNec5IG/HYL59a2TCmIl cardno:5407828";
in {
  internalIP = hostNumber: "10.105.102.${builtins.toString hostNumber}";
  munin-core = "core";
  rootPermittedKeys = [ danielSSHKey ];
  primary-ns = "services0";
  storageServer = "u356603.your-storagebox.de";
}
