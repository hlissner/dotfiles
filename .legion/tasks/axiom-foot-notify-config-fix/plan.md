# Axiom Foot Notify Config Fix

## Task Identity

- Name: Axiom Foot Notify Config Fix
- Task ID: `axiom-foot-notify-config-fix`
- Trigger: user reported Foot refuses to open because `/home/c1/.config/foot/foot.global.ini` contains `[main].notify`, which the installed Foot version rejects as an invalid option.
- Base ref: `origin/master`

## Goal

Make Foot start again on Axiom by removing or correcting the invalid repository-generated Foot `notify` option while preserving the rest of the terminal configuration.

## Problem

The active terminal path is blocked before the shell starts because Foot validates its generated config and aborts on an unsupported `notify` key in the `[main]` section. This is a runtime compatibility issue between the checked-in/generated Foot config and the installed Foot option set, not a request to replace the terminal stack.

## Acceptance Criteria

- Generated or checked-in Foot config no longer emits `[main].notify` when unsupported by the configured Foot package.
- Foot config validation or an equivalent `foot --check-config` style smoke passes if available.
- The fix stays scoped to Foot startup/config compatibility and does not redesign terminal bindings, shell startup, or desktop launcher behavior.
- Task evidence records the reported live failure and the repository-local validation result.

## Scope

- Locate the repository source that produces `foot.global.ini`.
- Remove or replace the invalid `notify` setting with the smallest compatible change.
- Run targeted validation for the Foot configuration and record the result.

## Non-Goals

- Do not change the default terminal away from Foot.
- Do not redesign notification behavior globally.
- Do not mutate live home configuration outside the repository/Nix path.
- Do not broaden this into an end4 or Hyprland hotkey task.

## Assumptions

- The live error text accurately identifies the active failing file and option.
- The configured Foot package does not support `notify` in `[main]`; removing the key is safer than adding version-specific compatibility logic unless validation shows a supported replacement.
- The tool session may not be able to launch an interactive terminal, so config validation is the primary repository-local check.

## Constraints

- Use the Legion worktree/PR lifecycle.
- Keep the fix minimal and preserve unrelated user/worktree changes.
- Keep generated-state and live-home mutations out of scope.

## Risks

- The desired bell/notification behavior may be lost if the old key was intended for another Foot version.
- Foot validation command availability may vary by package, requiring a fallback static/generated config check.

## Design Summary

- Treat the unsupported `notify` key as the startup blocker.
- Prefer deleting the invalid setting unless the installed Foot documentation or validation identifies a current supported replacement.
- Verify from the generated config path rather than only editing the source text.

## Phases

- Brainstorm: materialize this narrow hotfix contract.
- Engineer: inspect the Foot config source and patch the minimal compatibility fix.
- Verify: validate the generated Foot config and record evidence.
- Review/report/wiki: document readiness and ship through the PR lifecycle.
