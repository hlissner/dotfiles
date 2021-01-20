let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd+4ijlEHI98NLpgP/El73BmpBUfzka9ovdt8FoaVAG hlissner@home";
in {
  "bitwarden-smtp-env.age".publicKeys = [key];
  "gitea-smtp.age".publicKeys = [key];
}
