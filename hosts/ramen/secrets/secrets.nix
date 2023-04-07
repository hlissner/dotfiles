let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2zHkQNfDBGNmqMJhitIS07ZGU6N6E3g/SnDkLMeLDN";
in {
  "wg-homelab-key.age".publicKeys = [key];
}
