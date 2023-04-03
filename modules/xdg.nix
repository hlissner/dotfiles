# xdg.nix --- enforcing XDG compliance
#
# This module tries to enforce XDG compliance, whether programs want to or not,
# relegating the most stubborn programs to a fake $HOME (i.e. in ~/.local/user).
# But I hate that all this is necessary. There are a few (albeit important)
# projects that staunchly refuse these conventions, and never with good reason,
# so it's a lost cause. Best to just deal with it quickly so I can move on to
# more important things...

{ self, lib, pkgs, config, home-manager, ... }:

with builtins;
with lib;
let cfg = config.xdg;
in {
  options.xdg = with self.lib.options; {
    enable = mkBoolOpt true;
    ssh.enable = mkBoolOpt false;
    fakeHomeDir = mkOpt types.str ".local/user";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      ### A tidy $HOME is a tidy mind
      home-manager.users.${config.user.name}.xdg.enable = true;

      environment = {
        # Some GUI programs consult this, and ignore XDG conventions if it isn't
        # available (sigh).
        systemPackages = [ pkgs.xdg-user-dirs ];

        # These are set early in the login process by PAM; much sooner than
        # environment.variables, so the important variables go here.
        sessionVariables = rec {
          # This is not in the XDG standard. It's my jail for stubborn programs,
          # like Firefox, Steam, and LMMS.
          XDG_FAKE_HOME = "$HOME/${cfg.fakeHomeDir}";

          # These are the defaults, and xdg.enable does set them, but due to load
          # order, they're not set before environment.variables are set, which could
          # cause race conditions.
          XDG_BIN_HOME    = "$HOME/.local/bin";
          XDG_CACHE_HOME  = "$HOME/.cache";
          XDG_CONFIG_HOME = "$HOME/.config";
          XDG_DATA_HOME   = "$HOME/.local/share";
          XDG_DESKTOP_DIR = XDG_FAKE_HOME;
          XDG_STATE_HOME  = "$HOME/.local/state";

          # To avoid ~/.compose-cache getting created, and must be set
          # especially early to intercept this silliness:
          # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/x11/display-managers/default.nix#L74-L83
          XCOMPOSECACHE = "$XDG_RUNTIME_DIR/xcompose";
        };

        # Conform common programs to XDG conventions, leaving the rest to their
        # respective modules.
        variables = {
          # Common shells
          BASH_COMPLETION_USER_FILE = "$XDG_CONFIG_HOME/bash/completion";
          ENV             = "$XDG_CONFIG_HOME/shell/shrc";  # sh, ksh
          HISTFILE        = ''$XDG_STATE_HOME/''${SHELL##*/}/history'';
          # Common databases
          MYSQL_HISTFILE  = "$XDG_STATE_HOME/mysql/history";
          PGPASSFILE      = "$XDG_CONFIG_HOME/pg/pgpass";
          PGSERVICEFILE   = "$XDG_CONFIG_HOME/pg";
          PSQLRC          = "$XDG_CONFIG_HOME/pg/psqlrc";
          PSQL_HISTORY    = "$XDG_STATE_HOME/psql_history";
          SQLITE_HISTORY  = "$XDG_DATA_HOME/sqlite/history";
          # Misc
          ASPELL_CONF = ''
            per-conf $XDG_CONFIG_HOME/aspell/aspell.conf;
            personal $XDG_CONFIG_HOME/aspell/en_US.pws;
            repl $XDG_CONFIG_HOME/aspell/en.prepl;
          '';
          BZRPATH         = "$XDG_CONFIG_HOME/bazaar";
          BZR_HOME        = "$XDG_CACHE_HOME/bazaar";
          BZR_PLUGIN_PATH = "$XDG_DATA_HOME/bazaar";
          DVDCSS_CACHE    = "$XDG_CACHE_HOME/dvdcss";
          ICEAUTHORITY    = "$XDG_CACHE_HOME/ICEauthority";
          INPUTRC         = "$XDG_CONFIG_HOME/readline/inputrc";
          LESSHISTFILE    = "$XDG_STATE_HOME/less/history";
          LESSKEY         = "$XDG_CONFIG_HOME/less/keys";
          SUBVERSION_HOME = "$XDG_CONFIG_HOME/subversion";
          WGETRC          = "$XDG_CONFIG_HOME/wgetrc";
          __GL_SHADER_DISK_CACHE_PATH = "$XDG_CACHE_HOME/nv";
        };

        # For programs that don't expose an envvar or for whom XDG compliance is
        # only relevant during interactive shell use.
        shellAliases = {
          sqlite3 = ''sqlite3 -init "$XDG_CONFIG_HOME/sqlite3/sqliterc"'';
          wget = ''wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'';
        };
      };

      # Different (GUI) prorgams have competing opinions about what should go
      # where. Some ignore the envvars and only listen to xdg-user-dirs (thus
      # necessitating a user-dirs.dirs file), others (that may otherwise support
      # the convention) barrel on ahead and create files in $HOME anyway before
      # doing the right thing, and a few decide to create+pollute a
      # (non-dotfile) subfolder in (like Documents or Videos). What can I say?
      # Linux is a battlefield.
      home.configFile."user-dirs.dirs".text = ''
        XDG_DESKTOP_DIR="${cfg.fakeHomeDir}/Desktop"
        XDG_DOCUMENTS_DIR="${cfg.fakeHomeDir}/Documents"
        XDG_DOWNLOAD_DIR="${cfg.fakeHomeDir}/Downloads"
        XDG_MUSIC_DIR="${cfg.fakeHomeDir}/Music"
        XDG_PICTURES_DIR="${cfg.fakeHomeDir}/Pictures"
        XDG_PUBLICSHARE_DIR="${cfg.fakeHomeDir}/Share"
        XDG_TEMPLATES_DIR="${cfg.fakeHomeDir}/Templates"
        XDG_VIDEOS_DIR="${cfg.fakeHomeDir}/Videos"
      '';

      # Auto-create XDG directories, ensure correct permissions, and generate a
      # fake $HOME in XDG_DATA_HOME for jailing silly programs and their even
      # sillier developers for resisting XDG conventions.
      # Some tools may auto-create them with overly permissive defaults OR may
      # not create them at all when trying to write them, causing errors. Best
      # to do it right from the start.
      system.userActivationScripts.initXDG = ''
        for dir in "$XDG_DESKTOP_DIR" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_CONFIG_HOME"; do
          mkdir -p "$dir" -m 700
        done

        # Populate the fake home with .local and .config, so certain things are
        # still in scope for the jailed programs, like fonts, data, and files,
        # should they choose to use them at all.
        fakehome="${cfg.fakeHomeDir}"
        mkdir -p "$fakehome" -m 755
        [ -e "$fakehome/.local" ]  || ln -sf ~/.local  "$fakehome/.local"
        [ -e "$fakehome/.config" ] || ln -sf ~/.config "$fakehome/.config"

        # Avoid the creation of ~/.pki (typically by Firefox), by ensuring NSS
        # finds this directory.
        rm -rf "$HOME/.pki"
        mkdir -p "$XDG_DATA_HOME/pki/nssdb"
      '';

      ## dbus-broker doesn't produce a $HOME/.dbus like the dbus daemon does.
      services.dbus.implementation = "broker";

      # Ensures .Xauthority is written (by the display manager or X11-compatible
      # programs) to $XDG_RUNTIME_DIR and /run/lightdm/*/, instead of $HOME.
      services.xserver.displayManager.lightdm.extraConfig = "user-authority-in-system-dir = true\n";
      services.xserver.displayManager.job.environment.XAUTHORITY = "$XDG_RUNTIME_DIR/xauthority";

      # See https://kdemonkey.blogspot.com/2008/04/magic-trick.html, then
      # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/x11/display-managers/default.nix#L74-L83
      # which would otherwise create $HOME/.compose-cache.
      services.xserver.displayManager.job.environment.XCOMPOSECACHE = "$XDG_RUNTIME_DIR/xcompose";
    }

    ## Forces SSH to respect XDG.
    # HACK: This could break tools that rely on openssh (and even openssh
    #   itself), like DropBear. None of my tools/workflows on my workstations
    #   are broken by this, so I can ignore it, but it's opt-in for a reason.
    #
    #   Only issue I've found, so far, is that ssh-keygen writes to ~/.ssh by
    #   default (use -f to overwrite).
    (let keyFiles = [ "id_dsa" "id_ecdsa" "id_ecdsa_sk" "id_ed25519" "id_ed25519_sk" "id_rsa" ];
         keyFilesStr = concatStringsSep " " keyFiles;
         sshConfigDir = "$XDG_CONFIG_HOME/ssh";
     in mkIf cfg.ssh.enable {
       # To spare us passing the extra options to the executables, we set these
       # in the system config file.
       programs.ssh.extraConfig = ''
         Host *
           ${concatMapStringsSep "\n" (key: "IdentityFile ~/.config/ssh/${key}") keyFiles}
           UserKnownHostsFile ~/.config/ssh/known_hosts
       '';

       environment.systemPackages = with pkgs; with self.lib.pkgs; [
         (mkWrapper openssh ''
           dir='${sshConfigDir}'
           cfg="$dir/config"
           wrapProgram "$out/bin/ssh" \
             --run "[ -s \"$cfg\" ] && opts='-F \"$cfg\"'" \
             --add-flags '$opts'
           wrapProgram "$out/bin/scp" \
             --run "[ -s \"$cfg\" ] && opts='-F \"$cfg\"'" \
             --add-flags '$opts'
           wrapProgram "$out/bin/ssh-add" \
             --run "dir=\"$dir\"" \
             --run 'args=()' \
             --run '[ $# -eq 0 ] && for f in ${keyFilesStr}; do [ -f "$dir/$f" ] && args+="$dir/$f"; done' \
             --add-flags '-H "$dir/known_hosts"' \
             --add-flags '-H "/etc/ssh/ssh_known_hosts"' \
             --add-flags '"''${args[@]}"'
         '')
         (mkWrapper ssh-copy-id ''
           wrapProgram "$out/bin/ssh-copy-id" \
             --run 'dir="${sshConfigDir}"' \
             --run 'opts=(); for f in ${keyFilesStr}; do [ -f "$dir/$f" ] && opts+="-i '$dir/$f'"; done' \
             --append-flags '"''${opts[@]}"'
         '')
       ];
     })
  ]);
}
