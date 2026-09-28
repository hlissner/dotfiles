# test/nixos/modules/wm/theme.nix --- tests for modules/wm/theme.nix
#
# The module turns every application's registered template into Noctalia's
# [theme.templates] table, which lands in config.toml through
# modules.wm.noctalia.settings. Noctalia skips a template it can't read
# and writes an empty output_path into its own config dir, both without a
# word, so the tests read that table back and check it against the disk.

{ evalConfig, presets, flake, lib, ... }:

with lib;
let
  # The module rides modules.wm.desktop, so every read goes through it.
  desktop = modules: evalConfig ([{ modules.wm.desktop = "hyprland"; }] ++ modules);
  theme = modules:
    (desktop modules).modules.wm.noctalia.settings.theme.templates;

  # A template with every optional key left unset.
  bare = theme [{
    modules.wm.theme.files.example.input_path = "/in";
  }];

  # What the on-disk checks read: every real host with a desktop, so an app
  # that starts registering a template is covered the moment a host enables
  # it, plus the template-bearing apps no host happens to run right now.
  configs = filter (c: c.modules.wm.desktop != null) (attrValues presets.hosts)
    ++ [ (desktop [{
      modules.shell.tmux.enable = true;
      modules.shell.zellij.enable = true;
      modules.apps.rofi.enable = true;
      modules.apps.term.foot.enable = true;
      modules.apps.browsers.librewolf.enable = true;
    }]) ];
  inputs = unique (concatMap
    (c: catAttrs "input_path" (attrValues c.modules.wm.theme.files)) configs);
in {
  ## The table.

  # The module has no enable option of its own (see modules/wm/theme.nix);
  # it rides the desktop's, and that is what keeps it from emitting a theme
  # table -- and the qt5ct/qt6ct files that select Noctalia's palette -- on a
  # headless host.
  testNothingIsWrittenWithoutTheDesktop =
    let c = presets.bare; in {
      expr = {
        table = c.modules.wm.noctalia.settings ? theme;
        qt    = c.home.configFile ? "qt6ct/qt6ct.conf";
      };
      expected = { table = false; qt = false; };
    };

  # Noctalia's qt builtin writes colors/noctalia.conf and stops -- no hook, no
  # envvar -- so these files are what actually puts the palette on a Qt app.
  testQtCtSelectsNoctaliasScheme =
    let c = presets.hyprland;
    in {
      expr = map (v: hasInfix "color_scheme_path=${c.home.configDir}/${v}ct/colors/noctalia.conf"
                              c.home.configFile."${v}ct/${v}ct.conf".text)
                 [ "qt5" "qt6" ];
      expected = [ true true ];
    };

  ## Custom colors: a bare hex string is sugar for the submodule.

  testColorsNormalise = {
    expr = (theme [{
      modules.wm.theme.colors.brand = "#ff0000";
      modules.wm.theme.colors.accent = { color = "#00ff00"; blend = false; };
    }]).custom_colors;
    expected = {
      brand = { color = "#ff0000"; blend = true; };
      accent = { color = "#00ff00"; blend = false; };
    };
  };

  ## Templates.

  # An empty output_path would make Noctalia write to its config dir; an empty
  # hook would run a no-op shell. Unset keys have to disappear, set ones land.
  testUnsetTemplateKeysAreOmitted = {
    expr = {
      unset = attrNames bare.user.example;
      set = (theme [{
        modules.wm.theme.files.example = {
          input_path = "/in"; output_path = "/out"; pre_hook = "true";
        };
      }]).user.example;
    };
    expected = {
      unset = [ "input_path" ];
      set = { input_path = "/in"; output_path = "/out"; pre_hook = "true"; };
    };
  };

  # Upstream defaults enable_community_templates to true and community_ids to
  # empty, which renders nothing while looking enabled. The list drives the flag
  # so the two can't drift, and both are emitted even when empty -- a key this
  # config doesn't decide is a key `hey @noctalia reset` won't prune out of the
  # state file, where a tick in Settings beats anything here.
  testCommunityTemplatesDriveTheirFlag = {
    expr = map (ids:
      let t = theme [{ modules.wm.theme.communityTemplates = ids; }];
      in { inherit (t) enable_community_templates community_ids; })
      [ [] [ "tmux" ] ];
    expected = [
      { enable_community_templates = false; community_ids = []; }
      { enable_community_templates = true;  community_ids = [ "tmux" ]; }
    ];
  };

  ## Templates on disk.

  # Noctalia skips an input_path that isn't there without complaint, and its
  # engine can't be handed a font, so no template may ask for one -- fonts
  # come from nix, next to the rendered file. Both checked against the disk.
  testEveryTemplateInputExistsAndAsksForNoFont = {
    expr = rec {
      missing = filter (p: !(builtins.pathExists p)) inputs;
      fonts   = filter (p: hasInfix "theme.fonts" (readFile p)) (subtractLists missing inputs);
    };
    expected = { missing = []; fonts = []; };
  };

  # A token Noctalia doesn't have renders to "{{UNKNOWN:...}}", which counts as
  # an error, and one error means the whole file goes unwritten -- at runtime,
  # in a journal line nobody is tailing. Everything else in the batch still
  # renders and the engine skips files whose content didn't move, so the only
  # symptom is that one app stops following the theme. The canonical list is a
  # header in noctalia's source, read the way noctalia.nix reads its hooks.
  testEveryTemplateTokenExists =
    let
      header = "${flake.inputs.noctalia}/src/theme/tokens.h";
      tokens = map head (filter isList (split ''"([a-z_0-9]+)"'' (readFile header)));
      # Sugar the engine resolves before it looks anything up.
      aliases = [ "hover" "on_hover" ];
      # Seeded colors are never in the header; the engine grows these out of
      # each one at render time.
      derived = concatMap
        (n: [ n "on_${n}" "${n}_container" "on_${n}_container" "${n}_source" "${n}_value" ])
        (unique (concatMap (c: attrNames c.modules.wm.theme.colors) configs));
      used = path: map head (filter isList
        (split ''\{\{ *colors\.([a-z_0-9]+)\.'' (readFile path)));
    in {
      expr =
        if length tokens < 40
        then throw "No color tokens in ${header}; Noctalia moved them."
        else unique (concatMap (p: subtractLists (tokens ++ aliases ++ derived) (used p))
                               inputs);
      expected = [];
    };

  # hyprland.nix used to hardcode librewolf's profile directory, and drifted
  # from librewolf's own profileName option as a result.
  testLibrewolfFollowsProfileName = {
    expr = hasInfix "/librewolf/bob.default/"
      (theme [{
        modules.apps.browsers.librewolf.enable = true;
        modules.apps.browsers.librewolf.profileName = "bob";
      }]).user.librewolf-chrome-default.output_path;
    expected = true;
  };
}
