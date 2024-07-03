# modules/dev/lua.nix --- https://www.lua.org/
#
# I use lua for modding or Love2D for rapid gamedev prototyping (when godot is
# overkill and I have the luxury of avoiding JS). I write my Love games in
# fennel to get around some of lua's idiosynchrosies. That said, I install
# love2d on a per-project basis, so this module is rarely enabled.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let devCfg = config.modules.dev;
    cfg = devCfg.lua;
in {
  options.modules.dev.lua = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.enableXDG;
    love2D.enable = mkBoolOpt false;
    fennel.enable = mkBoolOpt false;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        lua
        luajit
        (mkIf cfg.love2D.enable love2d)
        (mkIf cfg.fennel.enable fennel)
      ];
    })

    (mkIf cfg.xdg.enable {
      # The lua ecosystem has great XDG support out of the box, so...
    })
  ];
}
