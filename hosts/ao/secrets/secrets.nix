let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd+4ijlEHI98NLpgP/El73BmpBUfzka9ovdt8FoaVAG hlissner@home";
in {
  "vaultwarden-smtp-env.age".publicKeys = [key];
  "mailgun-smtp-username.age".publicKeys = [key];
  "mailgun-smtp-secret.age".publicKeys = [key];
}
