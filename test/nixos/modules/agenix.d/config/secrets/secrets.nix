# A stand-in for config/secrets/secrets.nix. Nothing here is encrypted or
# decrypted; the suite only asks whether the entry is found and forwarded.
{
  "foo.age" = {
    publicKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA test" ];
    owner = "nobody";
  };
}
