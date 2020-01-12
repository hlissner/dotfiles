{ config, pkgs, lib, ... }:

{
  my = {
    packages = with pkgs; [
      (pass.withExtensions (exts: [
        exts.pass-otp
        exts.pass-genphrase
      ]))
    ];
    env.PASSWORD_STORE_DIR = "$HOME/.secrets/password-store";
  };
}
