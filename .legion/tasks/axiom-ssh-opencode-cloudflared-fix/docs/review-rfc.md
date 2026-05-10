# Review RFC: Axiom SSH Autossh and Opencode Cloudflared Fix

## Verdict

PASS

## Current Review

The revised RFC is implementable, bounded, verifiable enough for local evaluation, and has explicit rollback plus external Cloudflare handoff boundaries.

## Previously Blocking Findings

1. RESOLVED: `modules/services/cloudflared.nix` was added to authorized scope for the directly related Linux secret group fix. The RFC now requires Darwin to keep `staff` and Linux to use `users`, aligned with the Linux service group.

2. RESOLVED: The RFC now includes `cloudflared tunnel route dns home-axiom opencode-axiom.0xc1.space` in rollout and verification, with explicit blocker handling if Cloudflare CLI/account state prevents route creation.

## Remaining Non-blocking Risks

- Remote autossh auth, remote port `2224`, Cloudflare Access policy, and live browser access remain deployment-time checks that local Nix evaluation cannot prove.

---

## Initial Review

### Verdict

FAIL

### Blocking Findings

1. `modules/services/cloudflared.nix` hard-codes `age.secrets."cloudflared-credentials".group = "staff"`, but `axiom` is NixOS and the existing Linux cloudflared service runs as group `users`. The RFC enables this module on `axiom` without addressing the Linux secret group, so implementation may evaluate or activate into a missing/wrong group boundary. This blocks implementation because the credential deployment path is required for cloudflared to run.

2. The RFC treats cloudflared ingress config as sufficient to expose `opencode-axiom.0xc1.space`, but Cloudflare Tunnel also needs a public hostname/DNS route such as `cloudflared tunnel route dns home-axiom opencode-axiom.0xc1.space`. Without this step or an explicit external blocker, the acceptance criterion for exposing the hostname is unverifiable and likely incomplete.

### Required RFC Updates

- Add `modules/services/cloudflared.nix` to authorized scope for the directly related Linux secret group fix, or choose a host-local group creation workaround and justify it.
- Update the cloudflared rollout and verification sections to include DNS/public-hostname route creation or a documented handoff if Cloudflare CLI/account state prevents it.

### Non-blocking Notes

- Consider implementing the SSH wrapper dynamic `-F` flags with shell arrays rather than a single string to avoid fragile splitting.
