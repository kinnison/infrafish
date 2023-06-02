{
  utils = {
    hostNumber = 1;
    ip = "192.168.122.190";
    port = 22;
    vpn = {
      core = ""; # Empty string means this is the core/lighthouse/whatever
      pubkey = "ey+lwXdJID0SJWE/4d0hRLogacFxBCd9aJqS/1JlqxI=";
    };
  };

  services0 = {
    hostNumber = 2;
    ip = "192.168.122.179";
    port = 22;
    vpn = {
      core = "utils";
      pubkey = "7X4EaBuuuRKJirAYSTceGR7vWNeN+XtSMlodJid3AGs=";
    };
  };
}
