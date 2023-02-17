{ self, lib, ... }:

with lib;
with self.lib;
{
  services.gemuGuest.enable = true;
}
