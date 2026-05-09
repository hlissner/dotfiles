# Change Review: Complete Axiom End4 Desktop Import

> Conclusion: PASS
> Date: 2026-05-09
> Reviewed evidence: staged implementation diff, `.legion/tasks/dots-hyprland-desktop-rfc/plan.md`, `docs/rfc.md`, `docs/review-rfc.md`, `docs/import-manifest.md`, `docs/test-report.md`

## Blocking Findings

None.

## Scope And Correctness Review

- Scope compliance: the staged change satisfies the no-substrate-only contract. `config/quickshell/ii/shell.qml` is imported and loads `IllogicalImpulseFamily`; `modules/desktop/quickshell.nix` defaults `configName = "ii"`; the old `config/quickshell/axiom-shell` path is explicitly deprecated and not the active runtime config.
- Import boundary: `docs/import-manifest.md` records the upstream commit, the `ii` tree, rounded-polygon submodule, matugen/fuzzel/Hyprland imports, omitted installer/generated/secret paths, and Nix-generated override files. The generated color outputs remain omitted from source.
- Nix wiring: targeted eval/build evidence covers the active Quickshell service ExecStart, linked `quickshell/ii` and `matugen` sources, generated Hyprland variables, wrapped Quickshell 0.3 package, and full Axiom toplevel build.
- Quickshell defaulting: the default config is now `ii`, and the offscreen smoke reached the expected compositor/backend limitation after resolving the `ii` entrypoint and QML imports.
- Hyprland layering/ownership: upstream `hyprland.conf` layers imported defaults while Axiom host facts are generated under `hypr/custom/*`, `monitors.conf`, and `workspaces.conf`; `$dontLoadDefaultExecs = 1` keeps session-service startup under Nix while retaining upstream visual/general/rules/keybind layers.
- Generated-state boundary: committed sources omit `colors.conf`, `hyprlock/colors.conf`, `fuzzel_theme.ini`, secrets, and local state; matugen outputs target mutable XDG config/state locations rather than committed files.
- Runtime packages: the implementation adds the major Qt/QML, shell, wallpaper/theme, media, clipboard, DDC/i2c, keyring, and service dependencies required for the imported end4 path. Some upstream optional actions still assume commands such as KDE control modules, `kitty`/`fish`, or Arch-style update commands; these are runtime UX compatibility risks, not blockers to load/readiness.

## Security Lens

Security review was applied because this change touches authentication/session UI, polkit, keyring-stored API keys, clipboard history, local hardware-control permissions, cloud/API/AI modules, and scripts that can run in the live Wayland session.

- Polkit/auth UX: imported `Quickshell.Services.Polkit` submits user-entered responses to the polkit flow and does not bypass authentication. Disabling the external KDE polkit agent avoids duplicate agents, but live-session confirmation remains important.
- AI/cloud/API modules: source is imported and default config exposes online AI models, Google Cloud helpers, and keyring storage, but online API calls require user-provided keys; command-execution tool calls require an explicit approval path in the UI before `bash -c` runs. No committed keys or credentials were found in the recorded secret scan.
- Secrets/generated state: API keys and Google service-account content are routed through `secret-tool`/keyring, while generated config/state stays outside committed source.
- Clipboard/privacy: `cliphist` is default-on for text and image capture through a Nix-owned watcher. This is within the accepted Phase 4/end4 UI scope but remains privacy-sensitive.
- Live-session scripts: imported wallpaper, screenshot/OCR, recorder, Hyprland, keyring, and AI helper scripts can touch the live session or user state when invoked. They were not run during review; no blocker was identified because upstream setup was not run and Nix owns service startup.

No exploitable trust-boundary bypass, secret commit, or privilege escalation blocker was identified in the staged change.

## Verification Sufficiency

Verification is sufficient for repository-local readiness in a TTY environment. The report clearly distinguishes host identity (`axiom`) from the lack of `WAYLAND_DISPLAY`/`HYPRLAND_INSTANCE_SIGNATURE`, runs Nix eval/build checks, static QML local-import scanning, generated-output/secret scans, package build, and a bounded offscreen Quickshell smoke. The missing live Hyprland/Wayland restart and hardware-backed UI exercise are explicitly documented residual risks rather than hidden gaps.

## Non-Blocking Findings / Residual Risks

- Live Wayland validation remains required after deployment: restart `quickshell.service`, inspect journal output, and exercise sidebars, overview/search, notifications, OSD, lock/session, wallpaper switching, polkit prompts, and hardware toggles in the actual Axiom session.
- Clipboard retention/pruning is still privacy-sensitive; define retention/clear UX for `cliphist` in follow-up.
- Upstream optional AI/cloud/function tooling is powerful. Follow-up should consider defaulting AI policy/tools more conservatively or documenting the approval/keying model prominently.
- Several upstream app commands remain Arch/KDE/kitty/fish-oriented; follow-up should map Quickshell `Config.options.apps.*` to Axiom/Nix defaults or hide unsupported actions.
- `.upstream/` is present as an untracked local import clone and should remain uncommitted/cleaned before PR finalization.

## Readiness Summary

PASS. The staged implementation and docs are ready to proceed to walkthrough/wiki/PR lifecycle, with live-session validation and the non-blocking privacy/runtime compatibility items tracked as residual risk.
