# Test Report: Cloudflare API Token Age Secret

## Summary

PASS. The new API token secret decrypts to the expected env-style shape without printing the token, the encrypted file does not contain the plaintext token marker, agenix can decrypt it using the local rules file, and the charlie Darwin system evaluates through a dry-run build.

## Commands

### Direct age decrypt pattern check

```bash
age -d -i "$HOME/.ssh/id_ed25519" hosts/charlie/secrets/cloudflare-api-token.age | rg -q '^API_TOKEN=cfut_'
rg -q 'cfut_' hosts/charlie/secrets/cloudflare-api-token.age
```

Result: PASS. Decrypted content matched `^API_TOKEN=cfut_`; encrypted file scan found no plaintext `cfut_` marker.

### agenix decrypt pattern check

```bash
cd hosts/charlie/secrets
agenix -d cloudflare-api-token.age | rg -q '^API_TOKEN=cfut_'
```

Result: PASS. `agenix` returned match exit code `0`; token value was not printed.

### Legion config JSON validation

```bash
jq empty .legion/config.json
```

Result: PASS.

### Diff whitespace check

```bash
git diff --check
```

Result: PASS.

### Charlie system dry-run evaluation

```bash
git add -N hosts/charlie/secrets/cloudflare-api-token.age hosts/charlie/secrets/secrets.nix .legion/tasks/cloudflare-api-token-age-secret/...
nix build .#darwinConfigurations.charlie.system --dry-run
```

Result: PASS. Nix evaluated the charlie system with the new files visible to the Git-backed flake and reported the derivations that would be built.

## Notes

- Two earlier direct attempts to evaluate `.config.age.secrets` via flake output failed because this flake exposes `darwinConfigurations.charlie.system`, not the nested config attribute path. The dry-run system build is the stronger applicable check for repository integration.
- The dry-run build was rerun after `git add -N` so new files were visible to flake evaluation.
- No command in this report printed the token value.
