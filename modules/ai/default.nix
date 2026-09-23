## modules/ai/default.nix
#
# The other labs' CLIs, for second opinions. `bin/ask` fronts all of them; its
# header is the user-facing half of this module. One client per file --
# claude.nix is the one I actually work in, the rest is the "am I sure?" pile:
#
#   codex.nix     ChatGPT, on a subscription login.
#   grok.nix      Grok, likewise.
#   aichat.nix    The catch-all, via OpenRouter, and the honest answer for the
#                 providers that were never going to be free.
#   deepseek.nix  A hook for a CLI that doesn't exist.
#
# There's no `modules.ai.enable`: every client carries its own switch, because
# which of them a host wants has never correlated. `enabled` below is the
# rollup, for the few things that care whether *any* of this is on.
#
# They come from the llm-agents flake rather than nixpkgs -- these CLIs ship a
# release a day and nixpkgs is a week behind on a good week. aichat is the
# exception; llm-agents doesn't carry it.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.ai;
in {
  options.modules.ai = with types; {
    enable = mkBoolOpt false;
  };

  config = mkMerge [
    {
      # llm-agents builds against its own nixpkgs, so without numtide's cache
      # every one of these is a from-scratch build of bun and friends.
      nix.settings = {
        extra-substituters = [ "https://cache.numtide.com" ];
        extra-trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };
    }

    (mkIf cfg.enable {
      environment.sessionVariables = {
        # Respect XDG, damn it!
        GROK_HOME = "${config.home.stateDir}/grok";
        CODEX_HOME = "${config.home.stateDir}/codex";
      };
      user.packages =
        let llm-agents = hey.inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        in with pkgs; [
          bubblewrap  # for grok's sandbox
          llm-agents.grok
          llm-agents.codex
        ];
    })
  ];
}
