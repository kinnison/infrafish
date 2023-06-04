# Wireguard library bits for Peppernix
{ ppfmisc }:

rec {
  # If we change the VPN network, change this
  hostIP = ppfmisc.internalIP;
  network = nr: "${hostIP nr}/24";
  host = nr: "${hostIP nr}/32";
}
