# xdg.nix
#
# Set up and enforce XDG compliance. Other modules will take care of their own,
# but this takes care of the general cases.

{ self, lib, pkgs, config, home-manager, ... }:

with lib;
with self.lib;
let cfg = config.xdg;
in {
  options.xdg = {
    enable = mkBoolOpt true;
    ssh.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      ### A tidy $HOME is a tidy mind
      home-manager.users.${config.user.name}.xdg.enable = true;

      # Auto-create XDG directories and ensure correct permissions. Some tools
      # may auto-create them with overly permissive defaults OR may not create
      # them at all when trying to write them, causing errors. Best to do it
      # right from the start.
      system.userActivationScripts.wacom = ''
        for dir in $XDG_STATE_HOME $XDG_DATA_HOME $XDG_CACHE_HOME $XDG_BIN_HOME $XDG_CONFIG_HOME; do
          mkdir -p $dir
          chmod 700 $dir
        done
      '';

      environment = {
        sessionVariables = {
          # Prevent auto-creation of XDG user directories (like Desktop,
          # Documents, etc), we move it to $XDG_DATA_HOME. The trailing slash is
          # necessary for some apps (like Firefox) to respect it. See
          # https://bugzilla.mozilla.org/show_bug.cgi?id=1082717
          XDG_DESKTOP_DIR = "$HOME/.local/share/desktop/";

          # These are the defaults, and xdg.enable does set them, but due to load
          # order, they're not set before environment.variables are set, which could
          # cause race conditions.
          XDG_CACHE_HOME  = "$HOME/.cache";
          XDG_CONFIG_HOME = "$HOME/.config";
          XDG_BIN_HOME    = "$HOME/.local/bin";
          XDG_DATA_HOME   = "$HOME/.local/share";
          XDG_STATE_HOME  = "$HOME/.local/state";
        };

        # Some programs ignore the envvars (like apps with Gnome/QT
        # compatibilty, or certain file managers) and end up auto-creating these
        # annoying directories in $HOME. I would rather impose my own structure
        # on $HOME, so I stow them away in $XDG_DATA_HOME.
        etc."xdg/user-dirs.defaults".text = ''
          XDG_DESKTOP_DIR="$HOME/.local/share/desktop"
          XDG_DOCUMENTS_DIR="$HOME/.local/share/xdg/documents"
          XDG_DOWNLOAD_DIR="$HOME/downloads"
          XDG_MUSIC_DIR="$HOME/.local/share/xdg/music"
          XDG_PICTURES_DIR="$HOME/.local/share/xdg/pictures"
          XDG_PUBLICSHARE_DIR="$HOME/.local/share/xdg/share"
          XDG_TEMPLATES_DIR="$HOME/.local/share/xdg/templates"
          XDG_VIDEOS_DIR="$HOME/.local/share/xdg/videos"
        '';

        variables = {
          # Conform more programs to XDG conventions. The rest are handled by their
          # respective modules.
          __GL_SHADER_DISK_CACHE_PATH = "$XDG_CACHE_HOME/nv";
          ASPELL_CONF = ''
            per-conf $XDG_CONFIG_HOME/aspell/aspell.conf;
            personal $XDG_CONFIG_HOME/aspell/en_US.pws;
            repl $XDG_CONFIG_HOME/aspell/en.prepl;
          '';
          DVDCSS_CACHE    = "$XDG_DATA_HOME/dvdcss";
          HISTFILE        = "$XDG_DATA_HOME/bash/history";
          INPUTRC         = "$XDG_CONFIG_HOME/readline/inputrc";
          LESSHISTFILE    = "$XDG_STATE_HOME/less/history";
          LESSKEY         = "$XDG_CONFIG_HOME/less/keys";
          WGETRC          = "$XDG_CONFIG_HOME/wgetrc";
          # Common shells
          BASH_COMPLETION_USER_FILE = "$XDG_CONFIG_HOME/bash/completion";
          ENV = "$XDG_CONFIG_HOME/shell/shrc";  # sh, ksh
          # PostgreSQL
          MYSQL_HISTFILE  = "$XDG_STATE_HOME/mysql/history";
          PGPASSFILE      = "$XDG_CONFIG_HOME/pg/pgpass";
          PGSERVICEFILE   = "$XDG_CONFIG_HOME/pg";
          PSQLRC          = "$XDG_CONFIG_HOME/pg/psqlrc";
          PSQL_HISTORY    = "$XDG_STATE_HOME/psql_history";
          # Tools I don't use
          BZRPATH         = "$XDG_CONFIG_HOME/bazaar";
          BZR_HOME        = "$XDG_CACHE_HOME/bazaar";
          BZR_PLUGIN_PATH = "$XDG_DATA_HOME/bazaar";
          ICEAUTHORITY    = "$XDG_CACHE_HOME/ICEauthority";
          SUBVERSION_HOME = "$XDG_CONFIG_HOME/subversion";
        };
      };

      ## dbus-broker doesn't produce a $HOME/.dbus like the dbus daemon does.
      services.dbus.implementation = "broker";

      # Ensure legacy GTK2 apps read/write its config to an XDG directory.
      # services.xserver.displayManager.job.environment.GTK2_RC_FILES = "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";

      # The authoritative way to inform the display manager of this file's new
      # location, and soon enough.
      # systemd.globalEnvironment.XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority";
      # services.xserver.displayManager.job.environment.XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority";

      # See https://kdemonkey.blogspot.com/2008/04/magic-trick.html, then
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/x11/display-managers/default.nix#L74-L83
      # which would otherwise create $HOME/.compose-cache.
      services.xserver.displayManager.job.environment.XCOMPOSECACHE = "$XDG_RUNTIME_DIR/xcompose";
    }

    ## Getting SSH to respect XDG -- HIGHLY EXPERIMENTAL. Expect jank.
    (mkIf cfg.ssh.enable {
      environment.systemPackages = with pkgs; [
        (writeShellScriptBin "ssh" ''
          if [ -s "$XDG_CONFIG_HOME/ssh/config" ]; then
            OPTS='-F $XDG_CONFIG_HOME/ssh/config'
          fi
          exec ${openssh}/bin/ssh $OPTS "$@"
        '')
        (writeShellScriptBin "scp" ''
          if [ -s "$XDG_CONFIG_HOME/ssh/config" ]; then
            OPTS='-F $XDG_CONFIG_HOME/ssh/config'
          fi
          exec ${openssh}/bin/scp $OPTS "$@"
        '')
        (writeShellScriptBin "ssh-copy-id" ''
          OPTS="-i \"$XDG_CONFIG_HOME/ssh/id_ed25519\" "
          OPTS+="-i \"$XDG_CONFIG_HOME/ssh/id_rsa\" "
          exec ${ssh-copy-id}/bin/ssh-copy-id "$@" $OPTS
        '')
      ];

      programs.ssh.extraConfig = ''
        Host *
          IdentityFile ~/.config/ssh/id_ed25519
          IdentityFile ~/.config/ssh/id_rsa
          UserKnownHostsFile ~/.config/ssh/known_hosts
      '';
    })
  ]);
}
