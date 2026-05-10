# Research Notes

## Problem Restatement

- `ssh azar` fails because the wrapped `ssh` command passes `$XDG_CONFIG_HOME/ssh/config` as a literal `-F` path when the XDG SSH config exists, so OpenSSH looks for a file named with the dollar expression instead of `/home/c1/.config/ssh/config`.
- `azar` should get the same reverse SSH access pattern as `charlie` and `axiom`, but with an independent remote loopback port and a daemon-backed local SSH target.
- `axiom` should run `opencode serve` under systemd and expose only that loopback service through a new Cloudflare tunnel hostname.

## Relevant Code / Entry Points

- `modules/xdg.nix:101-139` controls the Linux XDG SSH wrapper package for `ssh`, `scp`, `ssh-add`, and `ssh-copy-id`.
- `modules/xdg.nix:116-123` currently assigns `dir='$XDG_CONFIG_HOME/ssh'`, computes `cfg="$dir/config"`, then injects `-F "$cfg"`; because the shell assignment is single-quoted in the wrapper script, the variable reference remains literal.
- `hosts/charlie/default.nix:78-103` is the existing Darwin `autossh` reverse tunnel pattern, using remote loopback `127.0.0.1:2222` and `root@8.159.128.125`.
- `hosts/charlie/default.nix:105-156` is the existing opencode plus cloudflared pattern, using `127.0.0.1:4096` and `opencode-charlie.0xc1.space`.
- `hosts/axiom/default.nix:119-137` is the existing NixOS autossh systemd service using remote loopback `127.0.0.1:2223` and persistent `sshd.service`.
- `hosts/azar/default.nix:171-172` currently starts the SSH agent and uses OpenSSH socket activation, but has no autossh reverse tunnel service.
- `modules/services/cloudflared.nix:141-199` owns the cloudflared age secret, generated config file, and Linux systemd service shape.

## Existing Conventions

- Reverse SSH remote forwards bind remote loopback explicitly rather than all interfaces.
- `charlie` owns remote loopback port `2222`; `axiom` owns `2223`; `azar` should use the next reserved port, `2224`, unless deployment proves a conflict.
- NixOS autossh services should run as local user `c1` with `HOME=/home/c1`, matching user-owned SSH credentials instead of root SSH state.
- Cloudflared-managed opencode exposure should keep opencode listening only on `127.0.0.1:4096`; public reachability is through Cloudflare Tunnel and Access.

## Historical Decisions

- `.legion/wiki/decisions.md` records the current reverse SSH loopback bind and port ownership decisions for `charlie` and `axiom`.
- `.legion/wiki/tasks/axiom-autossh-reverse-ssh-tunnel.md` records the previous `axiom` autossh implementation and its validation boundary.
- `docs/charlie-macos-ssh-config.md:105-160` documents the existing charlie cloudflared/opencode exposure pattern and states that Cloudflare Access is an上线前置条件.

## Constraints & Non-goals

- Do not change `charlie` behavior.
- Do not commit plaintext Cloudflare tunnel credentials.
- Do not expose opencode on a non-loopback bind address.
- Do not claim Cloudflare Access policy is complete unless it is verified outside this repo.
- Do not deploy to physical `axiom` or `azar` from this environment without a separate user confirmation.

## Risks & Pitfalls

- The XDG SSH wrapper bug is a quoting/expansion bug, not a missing file: runtime shell must expand `XDG_CONFIG_HOME` before computing `cfg`.
- `ssh-add` and `ssh-copy-id` share the same literal-directory pattern; fixing only `ssh` and `scp` would leave partial XDG breakage.
- `azar` currently uses `services.openssh.startWhenNeeded = true`; forwarding to local `127.0.0.1:22` is safer with a persistent `sshd.service`, matching the previous `axiom` fix.
- Cloudflared tunnel creation depends on an external Cloudflare login, account state, DNS route state, and Access policy; local Nix evaluation cannot prove those are correct.
- Age encryption must target a key deployable on `axiom`; a wrongly encrypted secret will evaluate but fail at activation/runtime.

## Unknowns

- [ ] Whether remote port `2224` is free on `8.159.128.125`; verify after deployment with autossh logs or remote `ss` output.
- [ ] Whether Cloudflare Access application and allow policy for `opencode-axiom.0xc1.space` already exist; verify in Cloudflare Zero Trust before treating public access as online.
- [ ] Whether the local Cloudflare login can create the new tunnel non-interactively in this automation session; if not, hand off exact commands.

## References

- Plan: `.legion/tasks/axiom-ssh-opencode-cloudflared-fix/plan.md`
- Existing autossh wiki: `.legion/wiki/tasks/axiom-autossh-reverse-ssh-tunnel.md`
- Current decisions: `.legion/wiki/decisions.md`
- Code: `modules/xdg.nix`, `hosts/azar/default.nix`, `hosts/axiom/default.nix`, `hosts/charlie/default.nix`, `modules/services/cloudflared.nix`
