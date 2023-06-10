{
  core = {
    hostNumber = 1;
    ip = "188.246.206.159";
    port = 22;
    vpn = {
      core = ""; # Empty string means this is the core/lighthouse/whatever
      pubkey = "ey+lwXdJID0SJWE/4d0hRLogacFxBCd9aJqS/1JlqxI=";
    };
  };

  services0 = {
    hostNumber = 2;
    ip = "188.246.206.160";
    port = 22;
    vpn = {
      core = "core";
      pubkey = "7X4EaBuuuRKJirAYSTceGR7vWNeN+XtSMlodJid3AGs=";
    };
  };
}
