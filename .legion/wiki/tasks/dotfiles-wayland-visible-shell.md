# Dotfiles Wayland Visible Shell

## Metadata

- `task-id`: `dotfiles-wayland-visible-shell`
- `status`: `active`
- `risk`: `medium`
- `schema-version`: `legion-wiki-v1`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes the `axiom` runtime state where Hyprland displayed a cursor but the desktop stayed black. The effective conclusion is that the compositor startup path must start `hyprland-session.target` before shell/wallpaper hooks and must not block on a foreground pseudo-login lock. DMS/Quickshell remains attached to the existing session targets; wallpaper remains a later startup hook through `swaybg`. Verification and readiness review passed; PR lifecycle, merge, cleanup, and main refresh are still pending while this summary is written.

## Reusable Decisions

- Hyprland startup should bootstrap the user session first: import compositor environment variables and start `hyprland-session.target` before visual shell or wallpaper hooks.
- Foreground `hyprlock --immediate` must not be used as an early startup gate for the product shell path; boot-time physical access protection needs a real greeter or non-blocking lock flow if it is required later.
- Visible-shell regressions need targeted evals for startup hooks, session target attachment, DMS/Quickshell service wiring, and wallpaper startup in addition to an `axiom` toplevel build.

## Related Raw Sources

- `plan`: `.legion/tasks/dotfiles-wayland-visible-shell/plan.md`
- `log`: `.legion/tasks/dotfiles-wayland-visible-shell/log.md`
- `tasks`: `.legion/tasks/dotfiles-wayland-visible-shell/tasks.md`
- `test-report`: `.legion/tasks/dotfiles-wayland-visible-shell/docs/test-report.md`
- `review`: `.legion/tasks/dotfiles-wayland-visible-shell/docs/review-change.md`
- `report`: `.legion/tasks/dotfiles-wayland-visible-shell/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/dotfiles-wayland-visible-shell/docs/pr-body.md`

## Notes

- Physical visual validation on `axiom` remains the runtime residual risk.
- A future lock/greeter task should preserve the visible shell bootstrap rather than restoring foreground startup `hyprlock`.
