# Wireguard library bits for Peppernix

rec {
  # If we change the VPN network, change this
  hostIP = nr: "10.19.4.${builtins.toString nr}";
  network = nr: "${hostIP nr}/24";
  host = nr: "${hostIP nr}/32";
}
