# modules/shell/vaultwarden.nix
{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.shell.vaultwarden;
    gpgPinentry = config.programs.gnupg.agent.pinentryPackage;
    rbw = getExe pkgs.rbw;
    jq = getExe pkgs.jq;
in {
  options.modules.shell.vaultwarden = with types; {
    enable = mkBoolOpt false;
    settings = mkOpt (attrsOf (either str int)) {};
  };

  config = mkIf cfg.enable {
    user.packages = [ pkgs.rbw ];

    modules.shell.vaultwarden.settings.pinentry = mkDefault
      (if gpgPinentry != null
       then getExe gpgPinentry
       else getExe pkgs.pinentry-curses);

    # `rbw config set` stops the agent (and locks the vault) every time, so
    # only touch what's actually drifted, or every rebuild would lock me out.
    system.userActivationScripts.hey-init-rbw = ''
      current=$(${rbw} config show 2>/dev/null || echo '{}')
      ${concatStrings (mapAttrsToList (n: v: let v' = escapeShellArg (toString v); in ''
        if [ "$(echo "$current" | ${jq} -r '.${n} // empty')" != ${v'} ]; then
          ${rbw} config set ${n} ${v'} || echo "rbw: couldn't set ${n}" >&2
        fi
      '') cfg.settings)}
    '';
  };
}
