# RFC Review: Wayland Product Overhaul Architecture

> Date: 2026-05-08
> Stage: review-rfc

## Decision

PASS

The RFC is implementable, has credible verification gates, and defines rollback paths for the risky subsystems. The design can proceed to implementation under the Legion git-worktree PR lifecycle.

## Blocking Findings

None.

## Notes

- One-big-PR scope is high risk but accepted by the task contract and mitigated by internal milestones plus explicit verification evidence.
- Darwin is correctly treated as a boundary constraint only; concrete Darwin validation remains deferred to a Darwin machine.
- Zen source uncertainty is acceptable because the RFC defines an ordered package strategy and pause condition.
- DMS/Quickshell uncertainty is acceptable because DMS is preferred and fallback would require review if packageability failed.
- Removal strategy is clear: remove obsolete Linux desktop paths without shims and update retained host references.
- Network/Bluetooth reliability is scoped to workstation hardware.
- Steam tuning, rollback, and verification requirements are covered.
