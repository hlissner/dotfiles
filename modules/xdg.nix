# xdg.nix --- enforcing XDG compliance on any host

{ hey, lib, config, options, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let
  cfg = config.modules.xdg;
  home = config.home;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  mkEnvVar = name: value:
    if isLinux
    then { environment.sessionVariables.${name} = value; }
    else { environment.variables.${name} = value; };
in {
  imports = optional isLinux hey.inputs.home-manager.nixosModules.home-manager;

  options.modules.xdg = {
    enable = mkBoolOpt true;
    ssh.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    (if isLinux then mkMerge [
      {
        nix.settings.use-xdg-base-directories = true;

        environment = {
          systemPackages = [ pkgs.xdg-user-dirs ];
          sessionVariables = {
            __GL_SHADER_DISK_CACHE_PATH = "/tmp/nv";
            XCOMPOSECACHE = "/tmp/xcompose";
          };
          variables = {
            BASH_COMPLETION_USER_FILE = "$XDG_CONFIG_HOME/bash/completion";
            ENV             = "$XDG_CONFIG_HOME/shell/shrc";
            MYSQL_HISTFILE  = "$XDG_STATE_HOME/mysql/history";
            PGPASSFILE      = "$XDG_CONFIG_HOME/pg/pgpass";
            PGSERVICEFILE   = "$XDG_CONFIG_HOME/pg";
            PSQLRC          = "$XDG_CONFIG_HOME/pg/psqlrc";
            PSQL_HISTORY    = "$XDG_STATE_HOME/psql_history";
            SQLITE_HISTORY  = "$XDG_STATE_HOME/sqlite/history";
            ASPELL_CONF     = ''per-conf $XDG_CONFIG_HOME/aspell/aspell.conf; personal $XDG_CONFIG_HOME/aspell/en_US.pws; repl $XDG_CONFIG_HOME/aspell/en.prepl;'';
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
          };
          shellAliases = {
            sqlite3 = ''sqlite3 -init "$XDG_CONFIG_HOME/sqlite3/sqliterc"'';
            wget = ''wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'';
          };
          etc."xdg/user-dirs.conf".text = ''
            enabled=False
          '';
        };

        home.configFile."user-dirs.dirs" = {
          force = true;
          text = ''
            XDG_DESKTOP_DIR="${home.fakeDir}/Desktop"
            XDG_DOCUMENTS_DIR="${home.fakeDir}/Documents"
            XDG_DOWNLOAD_DIR="${home.fakeDir}/Downloads"
            XDG_MUSIC_DIR="${home.fakeDir}/Music"
            XDG_PICTURES_DIR="${home.fakeDir}/Pictures"
            XDG_PUBLICSHARE_DIR="${home.fakeDir}/Share"
            XDG_TEMPLATES_DIR="${home.fakeDir}/Templates"
            XDG_VIDEOS_DIR="${home.fakeDir}/Videos"
          '';
        };

        system.userActivationScripts.initXDG = ''
          for dir in "$XDG_DESKTOP_DIR" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_BIN_HOME" "$XDG_CONFIG_HOME"; do
            mkdir -p "$dir" -m 700
          done

          fakehome="${home.fakeDir}"
          mkdir -p "$fakehome" -m 755
          [ -e "$fakehome/.local" ]  || ln -sf ~/.local  "$fakehome/.local"
          [ -e "$fakehome/.config" ] || ln -sf ~/.config "$fakehome/.config"

          rm -rf "$HOME/.pki"
          mkdir -p "$XDG_DATA_HOME/pki/nssdb"
        '';

        services.dbus.implementation = "broker";
        services.xserver.displayManager.lightdm.extraConfig = "user-authority-in-system-dir = true\n";
        services.displayManager.environment.XAUTHORITY = "$XDG_RUNTIME_DIR/xauthority";
        services.displayManager.environment.XCOMPOSECACHE =
          config.environment.sessionVariables.XCOMPOSECACHE;
      }

      (let
         keyFiles = [ "id_ed25519" "id_ed25519_sk" "id_ecdsa" "id_ecdsa_sk" "id_rsa" "id_dsa" ];
         keyFilesStr = concatStringsSep " " keyFiles;
         sshConfigDir = "$XDG_CONFIG_HOME/ssh";
        in mkIf cfg.ssh.enable {
          programs.ssh.extraConfig = ''
            Host *
              IdentityFile ~/.ssh/id_ed25519
              ${concatMapStringsSep "\n" (key: "IdentityFile ~/.config/ssh/${key}") keyFiles}
              AddKeysToAgent yes
              UserKnownHostsFile ~/.config/ssh/known_hosts
          '';

          environment.systemPackages = with pkgs; with hey.lib.pkgs; [
            (mkWrapper openssh ''
              wrapProgram "$out/bin/ssh" \
                --run 'dir="$XDG_CONFIG_HOME/ssh"' \
                --run '[ -n "$XDG_CONFIG_HOME" ] || dir="$HOME/.config/ssh"' \
                --run 'cfg="$dir/config"' \
                --run 'opts=()' \
                --run '[ -s "$cfg" ] && opts=(-F "$cfg")' \
                --add-flags '"''${opts[@]}"'
              wrapProgram "$out/bin/scp" \
                --run 'dir="$XDG_CONFIG_HOME/ssh"' \
                --run '[ -n "$XDG_CONFIG_HOME" ] || dir="$HOME/.config/ssh"' \
                --run 'cfg="$dir/config"' \
                --run 'opts=()' \
                --run '[ -s "$cfg" ] && opts=(-F "$cfg")' \
                --add-flags '"''${opts[@]}"'
               wrapProgram "$out/bin/ssh-add" \
                 --run 'dir="$XDG_CONFIG_HOME/ssh"' \
                 --run '[ -n "$XDG_CONFIG_HOME" ] || dir="$HOME/.config/ssh"' \
                 --run 'args=()' \
                 --run '[ $# -eq 0 ] && [ -f "$HOME/.ssh/id_ed25519" ] && args+=("$HOME/.ssh/id_ed25519")' \
                 --run '[ $# -eq 0 ] && for f in ${keyFilesStr}; do [ -f "$dir/$f" ] && args+=("$dir/$f"); done' \
                --add-flags '-H "$dir/known_hosts"' \
                --add-flags '-H "/etc/ssh/ssh_known_hosts"' \
                --add-flags '"''${args[@]}"'
            '')
            (mkWrapper ssh-copy-id ''
              wrapProgram "$out/bin/ssh-copy-id" \
                --run 'dir="$XDG_CONFIG_HOME/ssh"' \
                --run '[ -n "$XDG_CONFIG_HOME" ] || dir="$HOME/.config/ssh"' \
                --run 'opts=(); for f in ${keyFilesStr}; do [ -f "$dir/$f" ] && opts+="-i '$dir/$f'"; done' \
                --append-flags '"''${opts[@]}"'
            '')
         ];
       })
    ] else {})

    (mkIf (isDarwin) (mkMerge [
      (mkEnvVar "XDG_CONFIG_HOME" "${config.user.home}/.config")
      (mkEnvVar "XDG_CACHE_HOME"  "${config.user.home}/.cache")
      (mkEnvVar "XDG_DATA_HOME"   "${config.user.home}/.local/share")
      (mkEnvVar "XDG_STATE_HOME"  "${config.user.home}/.local/state")
      (mkEnvVar "XDG_BIN_HOME"    "${config.user.home}/.local/bin")
      {
        system.activationScripts.ensureXDG.text = ''
          for dir in "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME"; do
            mkdir -p "$dir"
          done
        '';
      }
    ]))
  ]);
}
