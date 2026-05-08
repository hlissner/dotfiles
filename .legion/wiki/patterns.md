# Patterns

## Git Flake Validation With New Modules

When validating a Git-backed flake after adding new module files, mark those files as tracked or intent-to-add before running `nix eval`/`nix build`. Otherwise Nix may evaluate the Git source without untracked module files, and `_module.check = false` can hide missing option declarations.

Recommended pre-validation command shape:

```sh
git add -N <new-module-files>
```

The final commit must still add the files normally.
