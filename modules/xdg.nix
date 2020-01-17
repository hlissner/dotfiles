# modules/xdg.nix -- a tidy $HOME is a tidy mind

{ config, lib, pkgs, ... }:
{
  # Obey XDG conventions;
  my.home.xdg.enable = true;
  environment.variables = {
    # These are the defaults, but some applications are buggy when these lack
    # explicit values.
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_BIN_HOME    = "$HOME/.local/bin";
  };

  # Conform more programs to XDG conventions. The rest are handled by their
  # respective modules.
  my.env = {
    __GL_SHADER_DISK_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    CUDA_CACHE_PATH = "$XDG_CACHE_HOME/nv";
    HISTFILE = "$XDG_DATA_HOME/bash/history";
    INPUTRC = "$XDG_CACHE_HOME/readline/inputrc";
    LESSHISTFILE = "$XDG_CACHE_HOME/lesshst";
    WGETRC = "$XDG_CACHE_HOME/wgetrc";
    XAUTHORITY = "/tmp/Xauthority";
  };
  my.init = "[ -e ~/.Xauthority ] && mv -f ~/.Xauthority \"$XAUTHORITY\"";

  # Prevents ~/.esd_auth files by disabling the esound protocol module for
  # pulseaudio, which I likely don't need. Is there a better way?
  hardware.pulseaudio.configFile =
    let paConfigFile =
          with pkgs; runCommand "disablePulseaudioEsoundModule"
            { buildInputs = [ pulseaudio ]; } ''
              mkdir "$out"
              cp ${pulseaudio}/etc/pulse/default.pa "$out/default.pa"
              sed -i -e 's|load-module module-esound-protocol-unix|# ...|' "$out/default.pa"
            '';
      in lib.mkIf config.hardware.pulseaudio.enable
        "${paConfigFile}/default.pa";

  # Clean up leftovers, as much as we can
  system.activationScripts.clearHome = ''
    pushd /home/${config.my.username}
    rm -rf .compose-cache .nv .pki .dbus .fehbg
    [ -s .xsession-errors ] || rm -f .xsession-errors*
    popd
  '';
}
