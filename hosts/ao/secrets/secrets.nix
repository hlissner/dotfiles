let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd+4ijlEHI98NLpgP/El73BmpBUfzka9ovdt8FoaVAG hlissner@home";
in {
  "dns-env.age".publicKeys = [key];
  "geolite-apikey.age".publicKeys = [key];
  "gitea-smtp-secret.age".publicKeys = [key];
  "gitea-smtp-username.age".publicKeys = [key];
  "vaultwarden-env.age".publicKeys = [key];
  "wireguard.age".publicKeys = [key];
}
