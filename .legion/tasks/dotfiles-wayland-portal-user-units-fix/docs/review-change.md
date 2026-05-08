# Review Change: Portal User Units Fix

## Decision

PASS

## Blocking Findings

None.

## Notes

- `mkForce` is acceptable here because the failure is caused by merged module defaults duplicating portal packages into user units.
- The effective portal surface remains the intended Hyprland portal plus GTK fallback.
- Scope is limited to Hyprland portal configuration.

## Residual Risk

- Future host-specific portal additions should update the central forced list or intentionally override it with stronger priority.

## Security Lens

Applied lightly because xdg-desktop-portal is a desktop protocol/trust-boundary component. No security blocker found; the change constrains the portal backend set to the already intended Hyprland + GTK fallback.
