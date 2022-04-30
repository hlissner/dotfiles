let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd+4ijlEHI98NLpgP/El73BmpBUfzka9ovdt8FoaVAG hlissner@home";
in {
  "vaultwarden-env.age".publicKeys = [key];
  "gitea-smtp-username.age".publicKeys = [key];
  "gitea-smtp-secret.age".publicKeys = [key];
  "geolite-apikey.age".publicKeys = [key];
  "ddclient-config.age".publicKeys = [key];
}
