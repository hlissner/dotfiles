# Test Report: axiom-end4-polish-hotfix

## Final Status

PASS for repository-owned validation available from this non-graphical shell.

Live UI behavior still needs confirmation in an actual Hyprland/Quickshell session because this shell cannot press `Super+Space`, inspect focus ownership, render tray icons, or preview images on screen.

## Commands and Evidence

| Command | Result | What it proves |
|---|---:|---|
| `git diff --check` | PASS | The implementation diff has no whitespace/conflict-marker issues. |
| `rg -n "TEST_ALIVE" config/hypr modules/desktop` | PASS (no matches) | Repo-owned imported/generated Hyprland and desktop integration surfaces no longer call the removed `TEST_ALIVE` fallback probe. |
| `nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/hypr/custom/keybinds.conf".text'` | PASS | Generated host override for `hypr/custom/keybinds.conf` keeps end4 active and maps `Super+Space` to `qs -c $qsConfig ipc call startMenu toggle`, then `search toggle`, then fuzzel fallback. |
| `nix eval --impure --json --expr 'map (p: p.name or (builtins.baseNameOf (toString p))) (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.systemd.user.services.quickshell.path'` | PASS | Nix owns the Quickshell service PATH and includes runtime dependencies relevant to reported gaps, including `networkmanager`, `bluez`, `network-manager-applet`, `blueman`, `imagemagick`, `ffmpeg`, `mpvpaper`, `matugen`, `grim`, `slurp`, and related tools. |
| `nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.systemd.user.services.quickshell.serviceConfig.ExecStart'` | PASS | Quickshell user service still starts the imported end4 shell via `.../bin/quickshell --config ii`, not the legacy shell. |
| `nix eval --impure --raw --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.home-manager.users.c1.home.file.".config/quickshell/ii".source'` | PASS | Home Manager owns `.config/quickshell/ii` from the repository source copied to the Nix store. |
| `rg -n "target: \"shell\"|function alive\(|ipc call shell alive|target: \"startMenu\"|function toggle\(|ipc call startMenu toggle" config/quickshell/ii config/hypr/hyprland/keybinds.conf modules/desktop/hyprland.nix` | PASS | Static evidence shows the new `shell alive` IPC target exists, fallback probes call it, and `startMenu toggle` is exposed and used by generated `Super+Space`. |
| `rg -n "networkmanager|bluez|networkmanagerapplet|blueman|imagemagick|ffmpeg|mpvpaper|matugen|path = quickshellServicePath|ExecStart|--config ii|home.configFile|quickshell/ii" modules/desktop/quickshell.nix` | PASS | Static evidence confirms service PATH ownership and the packages needed for network/Bluetooth status, image thumbnail/preview, wallpaper, and theme generation paths. |
| `rg -n "wallpaperSwitchScriptPath|switchwall|--image|wallpaperSelectorToggle|wallpapersDirectory|sourcePath|wallpapersPath|generated/wallpaper|matugen" config/quickshell/ii modules/desktop/hyprland.nix` | PASS | Static evidence links the wallpaper selector/preset paths to `switchwall.sh --image`, generated wallpaper state, and `matugen` theme generation. |
| `rg -n "end4PolishDockMigrated|dock\.enable = true|dock\.pinnedOnStartup = true|applyAxiomMigrations|left: true|leftMargin|anchors" config/quickshell/ii/modules/common/Config.qml config/quickshell/ii/modules/ii/dock/Dock.qml` | PASS | Static evidence shows dock defaults/migration enable and pin the dock, and the dock panel anchors to the left edge. |
| `rg -n "TEST_ALIVE" /nix/store/pi33gm0hyl3700fvz5n853db2jnziam6-source/config/quickshell/ii /home/c1/dotfiles/.worktrees/axiom-end4-polish-hotfix/config/hypr /home/c1/dotfiles/.worktrees/axiom-end4-polish-hotfix/modules/desktop || true` | PASS (no matches) | The evaluated store source for `quickshell/ii` plus repo Hypr/Nix surfaces contain no remaining `TEST_ALIVE` references. |
| `nix build --impure .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` | PASS | The full Axiom NixOS toplevel evaluates and builds with the changed Quickshell/Hyprland integration. Only pre-existing evaluation warnings were printed. |

Notes: several first-pass `nix eval .#...` commands failed because quoted Home Manager attribute names containing `.config/...` cannot be addressed through plain flake attr-path syntax. The corrected `--expr` commands above passed and are the evidence used for verification.

## Acceptance-Criteria Mapping

- `Super+Space` launcher/search: covered by generated keybind eval and static `startMenu` IPC evidence; focus intent is covered statically by `WlrKeyboardFocus.Exclusive` in the changed start menu/overview surfaces, but live typing must be verified in session.
- Network/Bluetooth and image preview checkerboards: covered by service PATH eval/static checks proving Nix supplies relevant network/Bluetooth tools and image/thumbnail/video tooling (`imagemagick`, `ffmpeg`, `mpvpaper`, etc.). Actual rendering remains live-session evidence.
- Preset wallpaper/theme path: covered by static checks for preset wallpaper directory, selector integration, `switchwall.sh --image`, generated wallpaper state, and `matugen`.
- Dock default/far-left placement: covered by static checks for enabled/pinned defaults, migration flag, and left-edge anchors.
- Keep end4 `ii` active: covered by Quickshell `ExecStart --config ii` eval and Home Manager `.config/quickshell/ii` source eval.
- Nix ownership: covered by generated Hypr config, Quickshell service PATH, ExecStart, and Home Manager source evals.

## Live-Session Limitations / Residual Risk

- This environment is non-graphical, so I could not trigger Hyprland keybinds, verify keyboard focus with real input, inspect rendered icon glyphs, or view actual image/wallpaper previews.
- Static/package validation strongly indicates the missing runtime/path/IPC gaps are addressed, but QML rendering and focus timing can still depend on the live compositor/session state.
- A live smoke test after deployment should press `Super+Space`, type into the launcher, open network/Bluetooth status, preview a recent screenshot/image, apply an end4 preset wallpaper, and confirm the dock appears pinned on the far-left edge.
