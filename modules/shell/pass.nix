{ config, pkgs, lib, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (pass.withExtensions (exts: [
        exts.pass-otp
        exts.pass-genphrase
      ]))
    ];

    variables.PASSWORD_STORE_DIR = "$HOME/.secrets/password-store";
  };
}
