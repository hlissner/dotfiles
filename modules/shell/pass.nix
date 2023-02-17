{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.shell.pass;
in {
  options.modules.shell.pass = with types; {
    enable = mkBoolOpt false;
    passwordStoreDir = mkOpt str "$HOME/.secrets/password-store";
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      (pass.withExtensions (exts: [
        exts.pass-otp
        exts.pass-genphrase
      ] ++ (if config.modules.shell.gnupg.enable
            then [ exts.pass-tomb ]
            else [])))
    ];
    env.PASSWORD_STORE_DIR = cfg.passwordStoreDir;
  };
}
