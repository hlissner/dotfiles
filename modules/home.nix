# modules/home.nix -- the $HOME manager
#
# This is NOT a home-manager home.nix file. Only its `home.{config,data}File`
# attr resembles home-manager's. The rest is a $HOME-management API for my nixos
# config.

{ hey, lib, config, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let cfg = config.home;

    fileType = with types; attrsOf (submodule {
      options = {
        text       = mkOpt (nullOr lines) null;
        source     = mkOpt (nullOr path) null;
        executable = mkBoolOpt false;
        recursive  = mkBoolOpt false;
      };
    });

    # Like home-manager, I snapshot a source outside the store, so an edit to it
    # waits for the next switch. *Link is for the ones that shouldn't.
    storeOf = rel: f:
      let name = strings.sanitizeDerivationName (baseNameOf rel);
          src = if builtins.hasContext (toString f.source) then f.source
                else builtins.path { path = f.source; inherit name; };
      in toString (
        if f.text != null then
          (if f.executable then pkgs.writeScript else pkgs.writeText) name f.text
        else if f.source == null then
          throw "home: ${rel} needs a text or a source"
        else if f.executable then
          pkgs.runCommandLocal name {} "install -m755 ${src} $out"
        else src);

    # A store source (self.configDir) carries string context, and a path can't
    # be built from one of those; the listing drops it, the targets keep it.
    targetsOf = files:
      let explode = rel: f:
            let src = storeOf rel f;
                root = builtins.unsafeDiscardStringContext (toString f.source);
            in listToAttrs (map
              (file: let r = removePrefix "${root}/" (toString file);
                     in nameValuePair "${rel}/${r}" "${src}/${r}")
              (filesystem.listFilesRecursive (/. + root)));
      in concatMapAttrs explode (filterAttrs (_: f: f.recursive) files)
         // mapAttrs storeOf (filterAttrs (_: f: !f.recursive) files);

    under = dir: mapAttrs'
      (rel: nameValuePair (if hasPrefix "/" rel then rel else "${dir}/${rel}"));

    links = mergeAttrsList [
      (under cfg.dir       (targetsOf cfg.file))
      (under cfg.fakeDir   (targetsOf cfg.fakeFile))
      (under cfg.configDir (targetsOf cfg.configFile // cfg.configLink))
      (under cfg.dataDir   (targetsOf cfg.dataFile   // cfg.dataLink))
      (under cfg.cacheDir  cfg.cacheLink)
      (under cfg.stateDir  cfg.stateLink)
    ];
in {
  options.home = with types; {
    file       = mkOpt' fileType {} "Files to place directly in $HOME";
    configFile = mkOpt' fileType {} "Files to place in $XDG_CONFIG_HOME";
    dataFile   = mkOpt' fileType {} "Files to place in $XDG_DATA_HOME";
    fakeFile   = mkOpt' fileType {} "Files to place in $XDG_FAKE_HOME";

    link       = mkOpt' (attrsOf str) {} "Symlinks to place directly in $HOME";
    cacheLink  = mkOpt' (attrsOf str) {} "Symlinks to $XDG_CACHE_HOME";
    configLink = mkOpt' (attrsOf str) {} "Symlinks to $XDG_CONFIG_HOME";
    dataLink   = mkOpt' (attrsOf str) {} "Symlinks to $XDG_DATA_HOME";
    stateLink  = mkOpt' (attrsOf str) {} "Symlinks to $XDG_STATE_HOME";

    dir        = mkOpt str "${config.user.home}";
    binDir     = mkOpt str "${cfg.dir}/.local/bin";
    cacheDir   = mkOpt str "${cfg.dir}/.cache";
    configDir  = mkOpt str "${cfg.dir}/.config";
    dataDir    = mkOpt str "${cfg.dir}/.local/share";
    stateDir   = mkOpt str "${cfg.dir}/.local/state";
    fakeDir    = mkOpt str "${cfg.dir}/.local/user";
  };

  config = {
    environment.localBinInPath = true;

    environment.sessionVariables = mkOrder 10 (
      # Deliberately $HOME-relative, so as not to hard-code these for all users.
      let underHome = dir:
            if hasPrefix "${cfg.dir}/" dir
            then "$HOME" + removePrefix cfg.dir dir
            else dir;
      in {
        # These are the defaults, and xdg.enable does set them, but due to load
        # order, they're not set before environment.variables are set, which
        # could cause race conditions.
        XDG_BIN_HOME    = underHome cfg.binDir;
        XDG_CACHE_HOME  = underHome cfg.cacheDir;
        XDG_CONFIG_HOME = underHome cfg.configDir;
        XDG_DATA_HOME   = underHome cfg.dataDir;
        XDG_STATE_HOME  = underHome cfg.stateDir;

        # This is not in the XDG standard. It's my jail for stubborn programs,
        # like Firefox, Steam, and LMMS.
        XDG_FAKE_HOME = underHome cfg.fakeDir;
        XDG_DESKTOP_DIR = underHome cfg.fakeDir;
      });

    home.link = links;

    # I keep a running list of the links I made, so what's dropped from the
    # config can be pruned now and later
    environment.etc."hey/links.conf".text = concatLines
      (mapAttrsToList (path: target: "${path}\t${target}")
        (under cfg.dir cfg.link));

    systemd.services.hey-home-links =
      let conf = "/etc/hey/links.conf";
          last = "${cfg.stateDir}/hey/links.conf";
      in {
        description = "Link home.* files into $HOME";
        wantedBy = [ "multi-user.target" ];
        unitConfig.RequiresMountsFor = cfg.dir;
        serviceConfig = { Type = "oneshot"; User = config.user.name; };
        path = [ pkgs.coreutils pkgs.gnugrep ];
        script = ''
          # On a fresh install's first boot this runs before anyone has logged
          # in, so before hey-init-xdg (xdg.nix), and mkdir -p won't fix a mode
          # after the fact. Same roots, same mode as it makes them.
          mkdir -pm700 ${toString (with cfg; [ binDir cacheDir configDir dataDir stateDir ])}
          bad=0
          if [ -f ${last} ]; then
            while IFS=$'\t' read -r path target; do
              grep -qxF "$path"$'\t'"$target" ${conf} && continue
              [ "$(readlink "$path")" = "$target" ] || continue
              rm -f "$path" && printf '\033[33m[hey] - %s\033[0m\n' "$path"
            done < ${last}
          fi
          while IFS=$'\t' read -r path target; do
            link=$(readlink "$path") || link=
            if [ "$link" != "$target" ]; then
              if [[ $link == /nix/store/* ]]; then
                rm -f "$path"
              elif [ -e "$path" ] || [ -L "$path" ]; then
                printf '\033[31m[hey] 𐄂 %s is in the way, skipping...\033[0m\n' "$path" >&2
                bad=$((bad + 1)); continue
              fi
              mkdir -p "''${path%/*}" && ln -s "$target" "$path" || {
                printf '\033[31m[hey] 𐄂 %s could not be linked\033[0m\n' "$path" >&2
                bad=$((bad + 1)); continue
              }
            fi
            printf '\033[32m[hey] ✓ %s\033[0m\n' "$path"
          done < ${conf}
          install -Dm644 ${conf} ${last}
          if [ "$bad" != 0 ]; then
            printf '\033[33m[hey] ⚠ %d link(s) failed. Fix and rerun `hey sync links`\033[0m\n' "$bad" >&2
            exit 1
          fi
        '';
      };
  };
}
