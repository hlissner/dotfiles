## modules/ai/aichat.nix
#
# The catch-all client. Whatever the other CLIs in here can't reach, aichat
# reaches over OpenRouter (see openrouter.nix).
#
# The one package in modules/ai/ still coming from nixpkgs: llm-agents doesn't
# carry aichat, and it's a plain rust CLI rather than one of the npm-shaped
# things that flake exists to keep current.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.ai.aichat;
in {
  options.modules.ai.aichat = with types; {
    enable = mkBoolOpt false;
    openrouterKeyFile = mkOpt' (nullOr str) null ''
      Path to a file holding the OpenRouter API key, read by `ask` at call time
      rather than exported into every process's environment. An
      `age.secrets.<name>.path` belongs here.
    '';
  };

  config = mkIf cfg.enable {
    user.packages = [ pkgs.aichat ];

    # aichat refuses to start without a config.yaml -- an empty $XDG dir isn't
    # enough -- so it gets one from the checkout like everything else here.
    # Keep it out of the store: aichat writes sessions and RAGs back into this
    # directory, and config.yaml itself is the only sane place to add a client.
    environment.variables = {
      AICHAT_CONFIG_DIR = "${hey.configDir}/aichat";
      OPENROUTER_API_KEY_FILE = cfg.openrouterKeyFile;
    };
  };
}
