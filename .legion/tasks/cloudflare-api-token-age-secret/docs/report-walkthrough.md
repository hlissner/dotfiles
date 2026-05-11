# Walkthrough: Cloudflare API Token Age Secret

## Mode

implementation

## Summary

- Added a separate age-encrypted Cloudflare API token secret at `hosts/charlie/secrets/cloudflare-api-token.age`.
- Added `hosts/charlie/secrets/secrets.nix` so agenix can decrypt/rekey the new API token secret with the intended recipient.
- Kept `cloudflared-credentials.age` unchanged and reserved for tunnel runtime credentials only.

## Why

The ignored local `cloudflare` file held the API token outside git, while the existing cloudflared `.age` file is a tunnel credentials JSON. A separate env-style secret makes the API token trackable without corrupting or overloading tunnel credentials.

## Evidence

- Contract: `.legion/tasks/cloudflare-api-token-age-secret/plan.md`
- Design: `.legion/tasks/cloudflare-api-token-age-secret/docs/rfc.md`
- RFC review: `.legion/tasks/cloudflare-api-token-age-secret/docs/review-rfc.md`
- Verification: `.legion/tasks/cloudflare-api-token-age-secret/docs/test-report.md`
- Change review: `.legion/tasks/cloudflare-api-token-age-secret/docs/review-change.md`

## Verification Summary

- Direct age decrypt pattern check: PASS.
- Encrypted file plaintext scan for `cfut_`: PASS, no match.
- agenix decrypt pattern check: PASS.
- `.legion/config.json` JSON validation: PASS.
- `git diff --check`: PASS.
- `nix build .#darwinConfigurations.charlie.system --dry-run`: PASS after `git add -N` made new files visible to the Git-backed flake.

## Residual Risk

The current token appeared in earlier tool output. This PR improves source control handling, but it does not rotate the Cloudflare token. Rotation remains a recommended follow-up.
