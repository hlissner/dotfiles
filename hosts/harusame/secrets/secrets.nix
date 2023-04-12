let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVNMxUyrezww+kbOuIQqYevhfLw2G1x8SKJpH5uPvOM";
in {
  "wg0PrivateKey.age".publicKeys = [key];
}
