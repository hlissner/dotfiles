# RFC: Cloudflare API Token Age Secret

## Context

The local ignored `cloudflare` file contains Cloudflare API automation metadata, including `API_TOKEN`. The existing `hosts/charlie/secrets/cloudflared-credentials.age` is not a general Cloudflare secret store; it decrypts to cloudflared tunnel runtime credentials JSON with `AccountTag`, `TunnelSecret`, `TunnelID`, and `Endpoint`.

The requested outcome is to make the API token git-trackable without committing plaintext and without changing the semantics of the existing tunnel credentials secret.

## Options

### Option A: Keep only the ignored plaintext file

Rejected. This preserves the current operational workflow but leaves the token outside git, so a fresh checkout cannot tell that the API token is an expected managed secret.

### Option B: Add API_TOKEN to cloudflared-credentials.age

Rejected. That file is consumed as cloudflared tunnel credentials JSON. Adding env-style API metadata would either corrupt the expected JSON shape or create a confusing mixed-purpose secret.

### Option C: Add a separate env-style age secret

Accepted. Create `hosts/charlie/secrets/cloudflare-api-token.age` containing only `API_TOKEN=...`, plus `hosts/charlie/secrets/secrets.nix` to record the recipient.

## Decision

Use Option C.

This keeps runtime tunnel credentials and API management credentials separate, makes the API token encrypted artifact git-trackable, and avoids changing existing scripts or local plaintext workflows in the same step.

## Security Notes

- The encrypted file must not contain a plaintext `cfut_` substring.
- Verification commands must only check patterns and must not print decrypted token content.
- The previously observed token exposure is out of scope for this change; rotation should be handled as a follow-up Cloudflare control-plane action.

## Verification

- Decrypt `hosts/charlie/secrets/cloudflare-api-token.age` with the intended identity and match `^API_TOKEN=cfut_` without printing the value.
- Search the encrypted `.age` file for `cfut_` and require no match.
- Run `agenix -d cloudflare-api-token.age` from `hosts/charlie/secrets` and match `^API_TOKEN=cfut_` without printing the value.
- Confirm git status shows the `.age` file and `secrets.nix` as tracked PR changes.

## Rollback

Remove `hosts/charlie/secrets/cloudflare-api-token.age`, remove its rule from `hosts/charlie/secrets/secrets.nix`, and leave the ignored local `cloudflare` file untouched. Existing cloudflared tunnel runtime behavior is unaffected because `cloudflared-credentials.age` is not modified.
