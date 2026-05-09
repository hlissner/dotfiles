# Dots Hyprland Desktop Phase 4 Implementation

## Task Identity

- Name: Dots Hyprland Desktop Phase 4 Implementation
- Task ID: `dots-hyprland-desktop-rfc`
- Restored from: historical design-only RFC task, now reopened as an implementation task by explicit user instruction.
- Current source of truth: this plan plus `docs/rfc.md`; theme-related direction must follow the repository-local `end4.md` requirements supplied for this continuation.

## Goal

Continue the Axiom Hyprland desktop migration by implementing the fourth phase from the end4-aligned plan: make the end4 Quickshell desktop surfaces and supporting NixOS services usable enough for launcher, overview, sidebars, control center, notification center, and related status/control capabilities to be traced to declarative configuration.

## Problem

The original task intentionally stopped at a design-only RFC. Subsequent implementation has already moved Axiom closer to an end4-style Quickshell desktop, but the task contract and RFC still describe an Axiom-native incremental shell and an `autumnal`-fallback theme direction. The current continuation explicitly changes that direction: end4's `ii` shell family and Material/Matugen-oriented theme model should be treated as the target, old Axiom desktop shell affordances should not be preserved for their own sake, and Phase 4 service capabilities need to be implemented through Nix rather than unmanaged live config.

## Acceptance Criteria

- `docs/rfc.md` is rewritten so the current phase model and theme decisions follow `end4.md`, not the historical Axiom-native fallback plan.
- The Phase 4 implementation keeps the end4 `ii` shell surfaces in scope: left sidebar, right sidebar/control center, overview, search/launcher, notification popup/center, OSD, wallpaper selector, session/lock, and polkit-facing UX where the current repository already carries those sources.
- `modules/desktop/quickshell.nix` or adjacent Nix modules declare the runtime tools needed by Phase 4 services: network, Bluetooth, audio, brightness, MPRIS/media, resource usage, tray, notifications, clipboard, and fallback control tools.
- NixOS/user setup declares the service capabilities Phase 4 depends on: NetworkManager, Bluetooth, PipeWire/WirePlumber, power profiles, keyring/polkit support, user cliphist watcher, i2c support, and required user groups.
- Theme-related statements no longer keep `autumnal` or old Axiom shell visuals as the desktop visual truth; end4 `IllogicalImpulseFamily`, Material Symbols/Google Sans-style font needs, Qt/Kirigami dependencies, matugen/wallpaper ownership, and generated-state boundaries are represented consistently.
- Validation evidence records the strongest feasible checks for Nix evaluation/build surfaces in this environment, plus any command that cannot run and why.
- Legion closing artifacts are updated: RFC review, test report, delivery walkthrough, PR body, wiki writeback, and task log.

## Assumptions

- The user-provided `end4.md` is authoritative for the new phase breakdown and theme direction, even when it conflicts with the historical RFC.
- Current Axiom still means the NixOS host and desktop modules under this repository, especially `hosts/axiom/default.nix`, `modules/desktop/*`, and `config/quickshell/*`.
- Upstream end4 remains a product/architecture reference; this task does not run an unmanaged end4 setup script or let live `~/.config` become the source of truth.
- The current repository may already contain earlier phase work; this task should extend it minimally rather than re-importing large upstream trees.
- PR delivery uses the mandatory Legion worktree lifecycle from base `origin/master`.

## Constraints

- Do not preserve backward compatibility with the old Axiom dock, old guide, old buttons, or autumnal desktop theme when they conflict with `end4.md`.
- Keep Darwin isolation and Axiom host facts declarative in Nix.
- Do not write secrets, API keys, generated color state, or mutable runtime cache into the Nix store or repository-managed source paths.
- Do not introduce unmanaged package managers, upstream installer state, or live home-directory edits.
- Keep Phase 4 bounded to service enablement and dependency/config ownership; deeper screenshot/OCR/translation/AI work remains later phase scope unless already required as a dependency for Phase 4 surfaces to load.

## Scope

- Rewrite the task contract and RFC from design-only future planning into a current Phase 4 implementation contract.
- Align the RFC's staged path with `end4.md`, including end4 theme truth and removal of old Axiom visual fallback language.
- Inspect the current Nix/Quickshell/Hyprland implementation state in the isolated worktree.
- Implement declarative Phase 4 service/package/user setup with the smallest correct changes.
- Record verification, review, walkthrough, wiki updates, and PR lifecycle state.

## Non-Goals

- Do not implement Phase 5 screenshot/OCR/translation/visual-search workflows beyond retaining dependencies already needed by current bindings or Phase 4 shell load.
- Do not implement Phase 6 AI/key policy work.
- Do not make generated Material You color outputs immutable or store-managed; Nix should own templates/scripts/dependencies, not mutable generated colors.
- Do not reintroduce Rofi/DMS/old Axiom shell components as primary UX.
- Do not perform manual runtime validation on the user's live Hyprland session from this environment.

## Design Summary

- Treat `end4.md` as the refreshed product contract: end4 `ii` shell family is the target UX, while Nix remains the source of truth for host facts, package closure, services, permissions, and generated-state boundaries.
- Phase 4 implementation should be declarative first: packages, services, groups, kernel modules, and user services must be visible in Nix modules rather than hidden inside shell scripts.
- The RFC should no longer describe `autumnal` as desktop fallback or keep Axiom-specific dock/guide language as a desired end state.
- Use fallback GUI tools only as operational fallbacks for incomplete inline controls, not as primary product direction.
- Prefer narrow module edits over large rewrites; add options only where host-specific facts or service toggles need to remain declarative.

## Risks

- Quickshell/end4 QML runtime dependencies can be broad; missing Qt/Kirigami packages may only appear during live shell startup.
- Hardware control features depend on permissions and devices (`video`, `input`, `i2c`, `i2c-dev`, `ddcutil`) that may not be fully testable in CI or a non-graphical environment.
- Notification/keyring/polkit overlap can conflict with other desktop services if ownership is unclear.
- Dynamic theme generation can blur source-of-truth boundaries if generated outputs are committed or written into store-owned paths.
- Broad dependency additions increase closure size and may need follow-up pruning after runtime validation.

## Phases

- Brainstorm/restore: rewrite the historical design-only contract into this implementation contract.
- Spec RFC: overhaul `docs/rfc.md` to reflect the end4.md-aligned staged migration and Phase 4 design.
- Review RFC: run an adversarial design review before implementation proceeds.
- Engineer: implement bounded Phase 4 Nix/config changes inside the Legion worktree.
- Verify Change: run feasible Nix/static validation and record a task-local test report.
- Review Change: assess delivery readiness, blockers, scope, and security implications.
- Report Walkthrough: produce reviewer-facing summary and PR body.
- Legion Wiki: write current truth and task summary back to `.legion/wiki`.
- PR Lifecycle: commit, rebase on `origin/master`, push, open/update PR, attempt auto-merge, follow checks/review, and finish cleanup/refresh when the PR reaches a terminal state.
