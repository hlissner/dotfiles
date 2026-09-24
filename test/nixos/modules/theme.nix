# test/nixos/modules/theme.nix --- tests for modules/hyprland/theme.nix
#
# The module turns every application's registered template into Noctalia's
# [theme.templates] table, which lands in config.toml through
# modules.hyprland.noctalia.settings. Noctalia skips a template it can't read
# and writes an empty output_path into its own config dir, both without a
# word, so the tests read that table back and check it against the disk.

{ evalConfig, flake, lib, ... }:

with lib;
let
  # The module rides modules.hyprland.enable, so every read goes through it.
  desktop = modules: evalConfig ([{ modules.hyprland.enable = true; }] ++ modules);
  theme = modules:
    (desktop modules).modules.hyprland.noctalia.settings.theme.templates;

  # The baseline every "is it absent?" test reads: a desktop with one
  # unrelated template in it (hyprland registers its own regardless).
  bare = theme [{
    modules.hyprland.theme.templates.example.input_path = "/in";
  }];

  # Everything that registers a template, switched on at once.
  everything = desktop [{
    modules.shell.tmux.enable = true;
    modules.shell.zellij.enable = true;
    modules.apps.rofi.enable = true;
    modules.apps.term.foot.enable = true;
    modules.apps.browsers.librewolf.enable = true;
  }];
in {
  ## The table.

  # The module has no enable option of its own (see modules/hyprland/theme.nix);
  # it rides the desktop's, and that is what keeps it from emitting a theme
  # table -- and the qt5ct/qt6ct files that select Noctalia's palette -- on a
  # headless host.
  testNothingIsWrittenWithoutTheDesktop =
    let c = evalConfig []; in {
      expr = {
        table = c.modules.hyprland.noctalia.settings ? theme;
        qt    = c.home.configFile ? "qt6ct/qt6ct.conf";
      };
      expected = { table = false; qt = false; };
    };

  # Noctalia's qt builtin writes colors/noctalia.conf and stops -- no hook, no
  # envvar -- so these files are what actually puts the palette on a Qt app.
  testQtCtSelectsNoctaliasScheme =
    let files = (desktop []).home.configFile;
    in {
      expr = map (v: hasInfix "color_scheme_path=/home/test/.config/${v}ct/colors/noctalia.conf"
                              files."${v}ct/${v}ct.conf".text)
                 [ "qt5" "qt6" ];
      expected = [ true true ];
    };

  ## Custom colors: a bare hex string is sugar for the submodule.

  testColorsNormalise = {
    expr = (theme [{
      modules.hyprland.theme.colors.brand = "#ff0000";
      modules.hyprland.theme.colors.accent = { color = "#00ff00"; blend = false; };
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
        modules.hyprland.theme.templates.example = {
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
      let t = theme [{ modules.hyprland.theme.communityTemplates = ids; }];
      in { inherit (t) enable_community_templates community_ids; })
      [ [] [ "tmux" ] ];
    expected = [
      { enable_community_templates = false; community_ids = []; }
      { enable_community_templates = true;  community_ids = [ "tmux" ]; }
    ];
  };

  ## Registration by the application modules.

  # Each module owns its own template, so what matters is that enabling the
  # application is what puts it in the table, and nothing else does.
  testAppsRegisterTheirTemplates =
    let user = everything.modules.hyprland.noctalia.settings.theme.templates.user;
        apps = [ "tmux" "zellij" "rofi" "foot"
                 "librewolf-chrome-default" "librewolf-content-alt" ];
    in {
      expr = {
        missing = filter (a: !(user ? ${a})) apps;
        leaked  = filter (a: bare.user ? ${a}) apps;
      };
      expected = { missing = []; leaked = []; };
    };

  # Noctalia skips an input_path that isn't there without complaint, and its
  # engine can't be handed a font, so no template may ask for one -- fonts
  # come from nix, next to the rendered file. Both checked against the disk.
  testEveryTemplateInputExistsAndAsksForNoFont =
    let templates = everything.modules.hyprland.theme.templates;
        input = name: templates.${name}.input_path;
    in {
      expr = {
        missing = filter (n: !(builtins.pathExists (input n))) (attrNames templates);
        fonts   = filter (n: hasInfix "theme.fonts" (readFile (input n))) (attrNames templates);
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
        (attrNames everything.modules.hyprland.theme.colors);
      templates = everything.modules.hyprland.theme.templates;
      used = name: map head (filter isList
        (split ''\{\{ *colors\.([a-z_0-9]+)\.'' (readFile templates.${name}.input_path)));
    in {
      expr =
        if length tokens < 40
        then throw "No color tokens in ${header}; Noctalia moved them."
        else unique (concatMap (n: subtractLists (tokens ++ aliases ++ derived) (used n))
                               (attrNames templates));
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
