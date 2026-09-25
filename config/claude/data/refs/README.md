# Local documentation mirrors

Offline copies of the docs for tools installed on this machine, each built and
kept current by `../../scripts/ensure-reference-NAME.zsh`. Run that before
reading `NAME/` -- it's silent and instant when nothing has changed -- then
grep before you read: these trees are large, and the answer is usually a few
lines of one file.

```sh
/etc/claude-code/scripts/ensure-reference-hyprland.zsh &&
  rg -l 'windowrule' /etc/claude-code/data/refs/hyprland/
```

`NAME/.version` says what a tree was built from.

| Tree | Built from | Matches what's installed? |
|---|---|---|
| `claude-code` | code.claude.com's `llms.txt` and the pages it lists | No -- upstream's latest as of the last time the installed CLI changed version |
| `hyprland` | wiki.hypr.land's own build for the installed version | Yes |
| `janet` | `core-api.md`: the installed interpreter; `manual/`: janet-lang.org | `core-api.md` exactly; `manual/` is the site as of the installed version's tag date |
| `nix` | The installed Nix's own manual | Yes |
| `nixos` | `options.*`: the installed nixpkgs; `options-local.index`: this repo's working tree | Yes, and the working tree respectively |
| `noctalia` | `docs/` of the installed flake input | Yes |

## Caveats worth repeating

- **claude-code/** -- for flag-level questions `claude --help` outranks this
  tree. `INDEX.short.txt` is the table of contents (path and title per page);
  `INDEX.txt` adds a sentence per page and is four times larger, so grep it
  rather than reading it.
- **janet/manual/** is only as close as a date gets it (the site has no
  tags). `janet/core-api.md` *is* exact -- it's dumped from the installed
  interpreter -- so prefer it for anything in the core library.
- **nixos/options.json** is tens of megabytes. Use `options.index`, then `jq`
  for the one record you want. This repo's own `modules.*` options are in
  `options-local.index`, not in either of those.
