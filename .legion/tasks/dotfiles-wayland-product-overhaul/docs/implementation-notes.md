# Implementation Notes

- Canonical Linux workstation verification target used locally: `ramen`, with additional evaluation for `harusame`, `udon`, `azar`, `atlas`, and `axiom` because they carried desktop references.
- Zen package source: nixpkgs/unstable did not expose `zen-browser`; branch uses narrow `github:0xc000022070/zen-browser-flake` input.
- DMS source: `pkgs.unstable.dms` is available; Quickshell and Matugen are provided from unstable.
- Discord source: `pkgs.unstable.vesktop` is used as the packageable Discord baseline; OpenAsar/Moonlight-specific package work is deferred because Vesktop provides the practical native-fixes/privacy/screenshare-oriented baseline available in nixpkgs.
