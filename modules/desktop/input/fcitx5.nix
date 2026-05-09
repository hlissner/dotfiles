{ hey, config, lib, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.desktop.input.fcitx5;
  themeName = "catppuccin-${cfg.theme.flavor}-${cfg.theme.accent}";
in {
  options.modules.desktop.input.fcitx5 = with types; {
    enable = mkBoolOpt false;
    waylandFrontend = mkBoolOpt false;
    extraAddons = mkOpt (listOf package) [];

    gtk.enable = mkBoolOpt true;
    qt.enable = mkBoolOpt true;

    rime.enable = mkBoolOpt false;
    pinyin.enable = mkBoolOpt false;

    theme = {
      enable = mkBoolOpt true;
      flavor = mkOpt (enum [ "latte" "frappe" "macchiato" "mocha" ]) "mocha";
      accent = mkOpt (enum [
        "blue"
        "flamingo"
        "green"
        "lavender"
        "maroon"
        "mauve"
        "peach"
        "pink"
        "red"
        "rosewater"
        "sapphire"
        "sky"
        "teal"
        "yellow"
      ]) "mauve";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          inherit (cfg) waylandFrontend;
          addons = cfg.extraAddons
            ++ optional cfg.gtk.enable pkgs.fcitx5-gtk
            ++ optional cfg.qt.enable pkgs.qt6Packages.fcitx5-qt
            ++ optional cfg.rime.enable pkgs.fcitx5-rime
            ++ optional cfg.pinyin.enable pkgs.qt6Packages.fcitx5-chinese-addons
            ++ optional cfg.theme.enable pkgs.catppuccin-fcitx5;
        };
      };
    }

    (mkIf cfg.theme.enable {
      i18n.inputMethod.fcitx5.settings.addons.classicui.globalSection.Theme = themeName;
      home.configFile."fcitx5/conf/classicui.conf" = {
        force = true;
        text = ''
          Theme=${themeName}
        '';
      };
    })
  ]);
}
