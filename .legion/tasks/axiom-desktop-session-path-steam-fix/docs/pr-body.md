## Summary
- Export a deterministic GUI session PATH from generated `uwsm/env` and import it into the systemd user manager.
- Include system packages in `caelestia-shell.service.path` so Caelestia/app2unit-launched children can resolve `git`, `gawk`, Steam, and other system-profile commands.
- Record Legion RFC, verification, review, and walkthrough evidence for the `axiom` desktop PATH/Steam launchability fix.

## Validation
- `DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.home.configFile.'"uwsm/env"'.text --raw`
- `DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.hey.hooks.startup.'"05-session"' --raw`
- `DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.systemd.user.services.caelestia-shell.path --apply 'packages: builtins.filter (name: name == "git" || name == "gawk" || name == "steam" || name == "steam-run" || name == "app2unit") (builtins.map (pkg: pkg.pname or pkg.name or "") packages)' --json`
- `DOTFILES_HOME="$PWD" nix eval --impure --no-eval-cache path:$PWD#nixosConfigurations.axiom.config.programs.steam.enable --json`
- `git diff --check`
- `DOTFILES_HOME="$PWD" nix build --impure --no-link path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel`

## Deployment Follow-up
- After switching `axiom`, verify Foot from the GUI can resolve `git` and `awk`.
- If Steam still fails after the PATH fix, capture Steam logs and split a Steam runtime follow-up.
