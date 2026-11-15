# test/nixos/modules/games/sunshine.nix --- tests for modules/games/sunshine.nix
#
# nixpkgs builds Sunshine without CUDA, and on Linux NVENC rides on CUDA. Lose
# the override and nothing fails: Sunshine lands on libx264 and the stream is
# the stuttery mess I left Steam for. So the GPU profile and the build are
# pinned to each other, with the expectation read off the package's inputs.

{ evalConfig, lib, ... }:

with lib;
let
  on = hw: evalConfig [{
    modules.games.sunshine.enable = true;
    modules.profiles.hardware = hw;
  }];
  hasCuda = c: any (p: hasPrefix "cuda_cudart" (p.pname or "")) c.services.sunshine.package.buildInputs;
in {
  testNvencIsBuiltOnlyWhereThereIsAnNvidiaCard = {
    expr = { nvidia = hasCuda (on [ "gpu/nvidia" ]); other = hasCuda (on []); };
    expected = { nvidia = true; other = false; };
  };

  # A mode without niri (or an output to apply it to) is a prep-cmd that dies
  # at session start, which Moonlight reports as the app refusing to launch
  # and nothing more. Asserted by count against the same config minus the mode.
  testModeSwitchingNeedsNiriAndAnOutput = {
    expr =
      let failing = c: length (filter (a: !a.assertion) c.assertions);
          niri = [{ modules.wm.desktop = "niri";
                    modules.wm.niri.monitors = [{ output = "HDMI-A-2"; primary = true; }]; }];
          extra = base: m:
            failing (evalConfig (base ++ [ m { modules.games.sunshine = { enable = true; clients.deck.mode = "1920x1080@60.000"; }; } ]))
            - failing (evalConfig (base ++ [ m { modules.games.sunshine.enable = true; } ]));
      in {
        bare = extra [] {};
        niriNoOutput = extra niri { modules.games.sunshine.output = null; };
        niri = extra niri {};
      };
    expected = { bare = 1; niriNoOutput = 1; niri = 0; };
  };
}
