let key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIsVpnMqt8WUOxPbUJRmfUhfdECxpDq5yGknf3OSw8oL";
in {
  "wg-homelab-key.age".publicKeys = [key];
}
