# Cloudflare API Token Age Secret

## Metadata

- `task-id`: `cloudflare-api-token-age-secret`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `2026-05-08-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task adds a dedicated age-encrypted Cloudflare API token secret for `charlie` while keeping cloudflared tunnel runtime credentials separate. The new tracked secret is `hosts/charlie/secrets/cloudflare-api-token.age`, with recipient rules in `hosts/charlie/secrets/secrets.nix`.

Validation confirmed the secret decrypts to an env-style `API_TOKEN=...` shape, the encrypted file does not contain the plaintext token marker, agenix can decrypt it from the secret directory, Legion config JSON is valid, and the charlie Darwin system dry-run evaluates.

The ignored local `cloudflare` plaintext file remains untouched for compatibility. Token rotation remains a follow-up because the current token appeared in earlier tool output.

## Reusable Decisions

- Cloudflare API management tokens should not be mixed into `cloudflared-credentials.age`; that file remains tunnel runtime JSON.
- Use a separate env-style age secret for API automation tokens, with validation that pattern-matches decrypted output without printing secret values.

## Related Raw Sources

- `plan`: `.legion/tasks/cloudflare-api-token-age-secret/plan.md`
- `log`: `.legion/tasks/cloudflare-api-token-age-secret/log.md`
- `tasks`: `.legion/tasks/cloudflare-api-token-age-secret/tasks.md`
- `rfc`: `.legion/tasks/cloudflare-api-token-age-secret/docs/rfc.md`
- `rfc-review`: `.legion/tasks/cloudflare-api-token-age-secret/docs/review-rfc.md`
- `test-report`: `.legion/tasks/cloudflare-api-token-age-secret/docs/test-report.md`
- `change-review`: `.legion/tasks/cloudflare-api-token-age-secret/docs/review-change.md`
- `report`: `.legion/tasks/cloudflare-api-token-age-secret/docs/report-walkthrough.md`
