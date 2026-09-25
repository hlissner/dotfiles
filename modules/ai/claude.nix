# modules/ai/claude.nix
#
# Oh AI, destroyer of the internet, open source, and all that is creative. Owned
# by the most morally bankrupt humans on Earth, a deleterious economic/politic
# force that does more bad than good, and when its bubble pops 2008 and 2001
# will look like vacations. Give me back affordable ram.

{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.ai.claude;
    settingsFormat = pkgs.formats.json {};

    llmAgents = hey.inputs.llm-agents.packages;
in {
  options.modules.ai.claude = with types; {
    enable = mkBoolOpt false;

    settings = mkOpt' settingsFormat.type {} ''
      Claude Code managed settings, written to
      /etc/claude-code/managed-settings.d/50-nixos.json.

      config/claude/managed-settings.d/10-defaults.json is the baseline for
      every host; this is where a host or another module adjusts it. Claude
      Code reads the drop-ins in filename order and merges them: a single
      value in a later file replaces the earlier one, lists union, and nested
      blocks (env, permissions, sandbox) merge key by key. So a host can set
      `settings.model = "sonnet"` or add to `settings.permissions.deny`
      without touching the shared file -- but it cannot *remove* a list entry
      the defaults set.

      Keys are documented in settings-reference.md, mirrored under
      /etc/claude-code/data/refs/claude-code/ (see
      config/claude/scripts/ensure-reference-claude-code.zsh).
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    ## The CLI itself ------------------------------------------------------
    {
      user.packages = [ llmAgents.claude-code ];

      environment.shellAliases = {
        cl  = "claude";
        cls = "claude --model sonnet";
        clo = "claude --model opus";
        clh = "claude --model haiku";
        clf = "claude --model fable";
      };

      # Respect XDG, damn it! The tmpfiles rule is that same directory; claude
      # keeps credentials in there, so nobody else gets to look.
      environment.sessionVariables.CLAUDE_CONFIG_DIR =
        "${config.home.dataDir}/claude";
      systemd.user.tmpfiles.rules = [ "d %h/.local/share/claude 700 - - - -" ];

      environment.etc =
        let claudeDir = "${hey.configDir}/claude";
            dropinDir = "${claudeDir}/managed-settings.d";
            install = sub: dir: entries: mapAttrs'
              (name: _: nameValuePair "claude-code/${sub}${name}" {
                source = "${dir}/${name}";
              })
              entries;
        in install "" claudeDir
            (removeAttrs (builtins.readDir claudeDir) [ "managed-settings.d" ])
          # Claude Code ignores hidden files in the drop-in directory; so do we.
          // install "managed-settings.d/" dropinDir
            (filterAttrs (n: _: !hasPrefix "." n) (builtins.readDir dropinDir));
    }

    (mkIf (cfg.settings != {}) {
      environment.etc."claude-code/managed-settings.d/50-nixos.json".source =
        settingsFormat.generate "claude-managed-settings-50-nixos.json" cfg.settings;
    })
  ]);
}
