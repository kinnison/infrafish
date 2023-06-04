# Miscellaneous configuration for Peppernix

{
  internalIP = hostNumber: "10.19.4.${builtins.toString hostNumber}";
  munin-core = "utils";
}
