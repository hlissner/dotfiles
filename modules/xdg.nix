# xdg.nix --- enforcing XDG compliance
#
# This module tries to enforce XDG compliance, whether programs want to or not,
# relegating the most stubborn programs to a fake $HOME (i.e. in ~/.local/user).
# But I hate that all this is necessary. There are a few (albeit important)
# projects that staunchly refuse these conventions, and never with good reason,
# so it's a lost cause. Best to just deal with it quickly so I can move on to
# more important things...
#
# PS. ValveSoftware/steam-for-linux#1890 is a gold mine.

{ hey, lib, config, options, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.modules.xdg;
    home = config.home;
    # Kept $HOME-relative, like modules/home.nix, so a value isn't hard-coded to
    # one user. PAM renders $HOME as @{HOME} and the shell profile expands it
    # directly; neither depends on the order variables are defined in.
    underHome = dir:
      if hasPrefix "${home.dir}/" dir
      then "$HOME" + removePrefix home.dir dir
      else dir;
    # Takes paths relative to DIR, and returns them under it.
    inDir = dir: mapAttrs (_: path: "${underHome dir}/${path}");
in {
  options.modules.xdg = {
    enable = mkBoolOpt true;
    ssh.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Get Nix (2.14+) itself to respect XDG. I.e.
      # ~/.nix-defexpr -> $XDG_DATA_HOME/nix/defexpr
      # ~/.nix-profile -> $XDG_DATA_HOME/nix/profile
      # ~/.nix-channels -> $XDG_DATA_HOME/nix/channels
      nix.settings.use-xdg-base-directories = true;


      ### A tidy $HOME is a tidy mind

      environment = {
        # Some GUI programs consult this, ignoring XDG conventions if it isn't
        # available (sigh).
        systemPackages = [ pkgs.xdg-user-dirs ];

        # These must be set early in the login process and end up in
        # /etc/set-environment, but also in the PAM env, where $XDG_*_HOME
        # variables aren't available, so we must build them from $HOME. More are
        # set from other modules.
        sessionVariables = {
          __GL_SHADER_DISK_CACHE_PATH = "/tmp/nv";

          # X11 systems only: prevents creation of ~/.compose-cache, and must be
          # set especially early to intercept this silliness:
          # https://github.com/NixOS/nixpkgs/blob/25865a40d14b3f9cf19f19b924e2ab4069b09588/nixos/modules/services/x11/display-managers/default.nix#L98-L105,
          XCOMPOSECACHE = "/tmp/xcompose";

          ASPELL_CONF =
            let f = p: "${underHome home.configDir}/aspell/${p}"; in
            "per-conf ${f "aspell.conf"}; personal ${f "en_US.pws"}; repl ${f "en.prepl"};";
        }
        // inDir home.configDir {
          BASH_COMPLETION_USER_FILE = "bash/completion";
          ENV           = "shell/shrc";       # sh, ksh
          INPUTRC       = "readline/inputrc"; # readline
          PGPASSFILE    = "pg/pgpass";        # postgres
          PGSERVICEFILE = "pg";
          PSQLRC        = "pg/psqlrc";
          WGETRC        = "wgetrc";
        }
        // inDir home.stateDir {
          MYSQL_HISTFILE = "mysql/history";
          PSQL_HISTORY   = "psql_history";
          SQLITE_HISTORY = "sqlite/history";
        }
        // inDir home.cacheDir {
          DVDCSS_CACHE = "dvdcss";
          ICEAUTHORITY = "ICEauthority";
        };

        # For programs that don't expose an envvar or for whom XDG compliance is
        # only relevant during interactive shell use.
        shellAliases = {
          sqlite3 = ''sqlite3 -init "$XDG_CONFIG_HOME/sqlite/sqliterc"'';
          wget = ''wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'';
        };

        # Don't recreate the $HOME/*/ XDG directories on login (in some desktop
        # environments).
        etc."xdg/user-dirs.conf".text = ''
          enabled=False
        '';
      };

      # Different (GUI) programs have competing opinions about what should go
      # where. Some ignore the envvars and only listen to xdg-user-dirs (thus
      # necessitating a user-dirs.dirs file), others (that may otherwise support
      # the convention) barrel on ahead and create files in $HOME anyway before
      # doing the right thing, and a few decide to pop a dotfile subfolder into
      # $HOME (like Documents or Videos). War. War never changes.
      home.configFile."user-dirs.dirs".text = ''
        XDG_DESKTOP_DIR="${home.fakeDir}/Desktop"
        XDG_DOCUMENTS_DIR="${home.dir}"
        XDG_DOWNLOAD_DIR="${home.dir}/downloads"
        XDG_MUSIC_DIR="${home.dir}"
        XDG_PICTURES_DIR="${home.dir}"
        XDG_PUBLICSHARE_DIR="${home.fakeDir}/Share"
        XDG_TEMPLATES_DIR="${home.fakeDir}/Templates"
        XDG_VIDEOS_DIR="${home.dir}"
      '';

      # Auto-create XDG directories, ensure correct permissions, and generate a
      # fake $HOME in XDG_DATA_HOME for jailing silly programs and their even
      # sillier developers for resisting XDG conventions. Some tools may
      # auto-create them with overly permissive defaults OR may not create them
      # at all when trying to write them, causing errors. Best to do it right
      # from the start.
      system.userActivationScripts.initXDG = ''
        for dir in "$XDG_DESKTOP_DIR" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_CONFIG_HOME"; do
          mkdir -p "$dir" -m 700
        done

        # Populate the fake home with .local and .config, so certain things are
        # still in scope for the jailed programs, like fonts, data, and files,
        # should they choose to use them at all.
        fakehome="${home.fakeDir}"
        mkdir -p "$fakehome" -m 755
        [ -e "$fakehome/.local" ]  || ln -sf ~/.local  "$fakehome/.local"
        [ -e "$fakehome/.config" ] || ln -sf ~/.config "$fakehome/.config"
        # For Flatpak
        [ -e "$fakehome/.var" ]    || ln -sf ~/.config "$fakehome/.var"

        # Avoid the creation of ~/.pki (typically by Firefox), by ensuring NSS
        # finds this directory.
        rm -rf "$HOME/.pki"
        mkdir -p "$XDG_DATA_HOME/pki/nssdb"
      '';

      # Ensures .Xauthority is written (by the display manager or X11-compatible
      # programs) to $XDG_RUNTIME_DIR and /run/lightdm/*/, instead of $HOME.
      services.xserver.displayManager.lightdm.extraConfig = "user-authority-in-system-dir = true\n";
      services.displayManager.generic.environment.XAUTHORITY = "$XDG_RUNTIME_DIR/xauthority";
    }

    ## Forcing SSH to respect XDG.
    # HACK: This could break tools that rely on openssh (and even openssh
    #   itself), like DropBear. None of my tools/workflows on my workstations
    #   are broken by this, so I can ignore it, but it's opt-in for a reason.
    #
    #   Only issue I've found, so far, is that ssh-keygen still generates into
    #   ~/.ssh by default (use -f to overwrite); its wrapper below only
    #   redirects the two modes that edit known_hosts.
    (let
       keyFiles = [ "id_ecdsa" "id_ecdsa_sk" "id_ed25519" "id_ed25519_sk" "id_rsa" ];
       keyFilesStr = concatStringsSep " " keyFiles;
       sshConfigDir = "$XDG_CONFIG_HOME/ssh";

       identityArgs = ''
         dir="${sshConfigDir}"
         case " $* " in
           *" -F "*) ;;
           *) [ -s "$dir/config" ] && cfg="$dir/config" ;;
         esac
         ids=()
         for f in ${keyFilesStr}; do
           [ -f "$dir/$f" ] && ids+=(-o "IdentityFile=$dir/$f")
         done
       '';

       wrapSshLike = prog: ''
         wrapProgram "$out/bin/${prog}" \
           --run ${escapeShellArg identityArgs} \
           --add-flags '${"$"}{cfg:+-F "$cfg"}' \
           --add-flags '"''${ids[@]}"'
       '';
     in mkIf cfg.ssh.enable {
       # A fallback when the wrappers aren't enough, like sshfs and nix-daemon,
       # those get no keys out of this, but they should at least agree with me
       # about hosts.
       programs.ssh.extraConfig = ''
         Host *
           UserKnownHostsFile ~/.config/ssh/known_hosts
       '';

       # HACK: The gotcha of this approach is $XDG_CONFIG_HOME/ssh/config needs
       #   to contain `Include /etc/ssh/ssh_config` to ensure system-wide
       #   settings are respected (ssh ignores the system config if -F is given,
       #   and it doesn't accept multiple).
       environment.systemPackages = with pkgs; with hey.lib.pkgs; [
         # Note to self: openssh's ssh-copy-id != pkgs.ssh-copy-id
         (mkWrapper openssh ''
           ${concatMapStrings wrapSshLike [ "ssh" "scp" "sftp" ]}
           # Given no arguments at all, ssh-add goes looking in ~/.ssh.
           wrapProgram "$out/bin/ssh-add" \
             --run ${escapeShellArg ''
               dir="${sshConfigDir}"
               args=()
               if [ $# -eq 0 ]; then
                 for f in ${keyFilesStr}; do
                   [ -f "$dir/$f" ] && args+=("$dir/$f")
                 done
                 if [ ''${#args[@]} -gt 0 ]; then
                   args=(-H "$dir/known_hosts" -H /etc/ssh/ssh_known_hosts "''${args[@]}")
                 fi
               fi
             ''} \
             --add-flags '"''${args[@]}"'
           # Which key to hand over, which is a different question from which
           # key to authenticate with, hence -i and not -o.
           wrapProgram "$out/bin/ssh-copy-id" \
             --run ${escapeShellArg ''
               dir="${sshConfigDir}"
               opts=()
               case " $* " in
                 *" -i "*) ;;
                 *)
                   for f in ${keyFilesStr}; do
                     [ -f "$dir/$f" ] && opts+=(-i "$dir/$f")
                   done
                   ;;
               esac
             ''} \
             --append-flags '"''${opts[@]}"'
           # -R and -F are the two modes that edit known_hosts, and the only
           # part of ssh-keygen I can talk out of ~/.ssh; everything else it
           # writes still wants an explicit -f.
           wrapProgram "$out/bin/ssh-keygen" \
             --run ${escapeShellArg ''
               args=()
               case " $* " in
                 *" -f "*) ;;
                 *" -R "*|*" -F "*) args=(-f "${sshConfigDir}/known_hosts") ;;
               esac
             ''} \
             --add-flags '"''${args[@]}"'
         '')
       ];
     })
  ]);
}
