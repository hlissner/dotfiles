## Summary

- Add a dedicated age-encrypted Cloudflare API token secret for charlie.
- Add the matching agenix recipient rule in `hosts/charlie/secrets/secrets.nix`.
- Keep cloudflared tunnel runtime credentials separate from Cloudflare API management credentials.

## Validation

- PASS: direct age decrypt pattern check for `^API_TOKEN=cfut_` without printing the value.
- PASS: encrypted `.age` file scan found no plaintext `cfut_` marker.
- PASS: agenix decrypt pattern check from `hosts/charlie/secrets`.
- PASS: `jq empty .legion/config.json`.
- PASS: `git diff --check`.
- PASS: `nix build .#darwinConfigurations.charlie.system --dry-run` after `git add -N` made new files visible to the Git-backed flake.

## Notes

- The ignored local `cloudflare` file is intentionally left untouched.
- The existing `cloudflared-credentials.age` is intentionally left untouched.
- The Cloudflare API token should still be rotated separately because it appeared in prior tool output.
