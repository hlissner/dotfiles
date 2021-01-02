{ ... }:

{
  ## System security tweaks
  boot.tmpOnTmpfs = true;
  security.hideProcessInformation = true;
  security.protectKernelImage = true;

  # Fix a security hole in place for backwards compatibility. See desc in
  # nixpkgs/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix
  boot.loader.systemd-boot.editor = false;

  # Change me later!
  user.initialPassword = "nixos";
  users.users.root.initialPassword = "nixos";

  # So we don't have to do this later...
  security.acme.acceptTerms = true;
}
