{
  core = {
    hostNumber = 1;
    ip = "188.246.206.159";
    port = 22;
    vpn = {
      core = ""; # Empty string means this is the core/lighthouse/whatever
      pubkey = "ey+lwXdJID0SJWE/4d0hRLogacFxBCd9aJqS/1JlqxI=";
    };
    storage-user = "u356603-sub1";
    mail = { core = true; };
  };

  services0 = {
    hostNumber = 2;
    ip = "188.246.206.160";
    port = 22;
    vpn = {
      core = "core";
      pubkey = "7X4EaBuuuRKJirAYSTceGR7vWNeN+XtSMlodJid3AGs=";
    };
    storage-user = "u356603-sub2";
    mail = { relay-ok = true; };
  };

  shell = {
    hostNumber = 3;
    ip = "188.246.206.184";
    port = 22;
    vpn = {
      core = "core";
      pubkey = "GLlW/SsDZ37+iDctVNAIi0IxsmgHy3iI7w2S6HgySQE=";
    };
    storage-user = "u356603-sub4";
    mail = { relay-ok = true; };
  };
}
