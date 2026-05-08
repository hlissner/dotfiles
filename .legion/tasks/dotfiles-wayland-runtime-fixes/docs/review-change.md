# Review Change

## Result

PASS

## Blocking Findings

None.

## Scope Review

The change stays within the approved scope:

- `modules/desktop/hyprland.nix` only adjusts the greetd/UWSM session entry name and uses the configured UWSM package.
- `modules/profiles/hardware/wifi.nix` only changes iwd DHCP/route ownership under NetworkManager.
- `hosts/axiom/default.nix` only moves wired DHCP/autoconnect from legacy dhcpcd ownership into NetworkManager.
- Legion task evidence was added under `.legion/tasks/dotfiles-wayland-runtime-fixes/`.

No browser, Steam, Discord, Bluetooth, broad Wayland, old X11 compatibility, secrets, or Darwin behavior changes were introduced.

## Correctness Review

- The evaluated `axiom` session list contains `hyprland-uwsm`; the old `hyprland.desktop` entry is absent. Updating greetd to `hyprland-uwsm.desktop` fixes the direct missing-entry failure.
- `config.programs.uwsm.package` aligns greetd with the UWSM package used by the NixOS UWSM module instead of hard-coding a separate unstable package path.
- Disabling iwd `EnableNetworkConfiguration` makes NetworkManager the DHCP/route owner while still using iwd as the Wi-Fi backend.
- The `enp14s0` NetworkManager ensure profile preserves wired DHCP/autoconnect behavior without enabling legacy `dhcpcd`.
- Verification evidence is adequate for this environment: actual `axiom` toplevel build passed, targeted evals prove session and network effective state, and `git diff --check` passed.

## Security Lens

Applied because the change touches login/session startup and network service ownership.

No security blocker found:

- No secrets or credentials were added.
- The wired NetworkManager profile uses DHCP/autoconnect for a specific physical interface, matching the previous wired DHCP intent but under the intended service owner.
- Disabling `dhcpcd` reduces duplicate privileged network daemons rather than adding one.
- The greetd command still runs the intended Hyprland session for the configured local user.

## Non-blocking Notes

- Runtime login and physical network checks still need to happen on `axiom`; the available validation proves the generated closure and effective Nix configuration, not live hardware behavior.
- The iwd `Network` section remains present but inert while `EnableNetworkConfiguration = false`; this is not a blocker because NetworkManager owns DHCP/routes.
