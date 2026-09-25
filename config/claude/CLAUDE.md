# Machine-local documentation

Offline doc mirrors for tools installed here, pinned to installed versions: `/etc/claude-code/data/refs/{claude-code,hyprland,janet,nix,nixos,noctalia}/`

**Always run `/etc/claude-code/scripts/ensure-reference-NAME.zsh` before consulting `data/refs/NAME/`.** It prints nothing and exits 0 when the tree is current, and otherwise rebuilds it first (seconds, occasionally a minute). Non-zero means it couldn't; its few lines of output say why, and the tree it left is stale or absent. `DEBUG=1` makes it talk.

Prefer these over fetching docs. Never read a whole page or index under `data/refs/`: `rg -n` first, then Read with offset/limit. For claude-code, `INDEX.short.txt` (path + title) is the TOC; `INDEX.txt` is for grep only. Read `data/refs/README.md` for per-tree version fidelity and caveats.
