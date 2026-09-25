## modules/ai/default.nix
#
# The other labs' CLIs, for second opinions. `bin/ask` fronts all of them; its
# header is the user-facing half of this module. claude.nix is the one I
# actually work in; the rest is the "am I sure?" pile:
#
#   codex       ChatGPT, on a subscription login.
#   grok        Grok, likewise.
#   gemini      Gemini, on a Google login.
#   aichat.nix  The catch-all, via OpenRouter, and the honest answer for the
#               providers that were never going to be free.
#
# The three subscription CLIs ride on `modules.ai.enable`, since I've never
# wanted one without the others. claude and aichat get their own switches.
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
        GEMINI_CLI_HOME = "${config.home.stateDir}/gemini";
      };
      user.packages =
        let llm-agents = hey.inputs.llm-agents.packages;
        in with pkgs; [
          bubblewrap  # for grok's sandbox
          llm-agents.grok
          llm-agents.codex
          llm-agents.gemini-cli
        ];
    })
  ];
}
