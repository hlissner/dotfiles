# modules/backup.nix --- in-house backup/restoration procedures
#
# A simple way to register certain file paths as backup targets. They will be
# incrementally backed up to /run/backups/$NAME/$DATE/.
# /run/backups/{backup,restore}.sh scripts will be available for easy backing up
# or restoration of said data.
#
# Warning: don't use me yet, it's a WIP.

{ options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.backup;

    backupType = with types; submodule ({ config, ... }: {
      options = {
        enable = mkBoolOpt false;

        name   = mkOpt' str config._module.args.name "Name of this backup";
        owner  = mkOpt str "backup";
        group  = mkOpt str users.${config.owner}.group;
        mode   = mkOpt str "0400";

        baseDir = mkOpt' (either str path) "" "Base directory for backup targets";
        targets = mkOpt' (listOf (either str path)) [] ''
          List of file globs or paths to files/directories that will be backed
          up (or restored) for this target. Paths are relative to this target's
          baseDir to modules.backup.path.
        '';

        backupScript = mkOpt' lines "" ''
          Script to run when backing up this target. The current directory is
          this target's baseDir and $outdir contains the backup destination.
        '';
        restoreScript = mkOpt' lines "" ''
          Script to run when restoring this target's backed up files. The
          current directory is this target's latest backup directory and $outdir
          contains the restoration destination.
        '';

        suspendServices = mkOpt (listOf str) [] ''
          Systemd services to suspend while backing up or restoring this target.
        '';
        maxGenerations = mkOpt' int cfg.maxGenerations ''
          How many generations of backups to keep in store
        '';
      };
    });

    targetBackupScript = target: writeShellScriptBin "backup.sh" ''
      ${optionalString (target.enable != true) ''
        echo "Skipping ${target.name} (reason: disabled)"
        exit 0
      ''}
      set -e
      basedir="${cfg.path}/${target.name}"
      indir="${target.baseDir}"
      outdir="$basedir/$(date +"%Y%m%d-%H%M%S)"

      # Ensure current generation's backup folder exists, and we're in it
      rm -rf "$outdir"
      mkdir -p "$outdir" && cd "$outdir"

      # Suspend dependent services
      ${concatStringSep "\n" (map (s: "systemctl stop ${s}") target.suspendServices)}

      # Backup individual targets
      ${concatStringSep "\n"
        (mapAttrsToList (n: v: ''cp -RTfpv "$indir/"${v} "$outdir/"'') target.targets)}

      # Launch custom script
      ${optionalString (target.backupScript != "") target.backupScript}

      # Clean up excess generations
      gens="$(ls -1dtr "$basedir" | head -n -${target.maxGenerations})"
      for gen in $gens; do rm -rf $gen; done
      ln -sf "$basedir/latest" "$outdir"

      # Resume services
      ${concatStringSep "\n" (map (s: "systemctl start ${s}") target.suspendServices)}
    '';

    targetRestoreScript = target: writeShellScriptBin "restore.sh" ''
      set -e
      indir="${cfg.path}/${target.name}/latest"
      outdir="${target.baseDir}"
      cd "$indir"

      # Suspend services
      ${concatStringSep "\n"
        (map (s: "systemctl stop #{s}") target.suspendServices)}

      # Restore individual targets
      ${concatStringSep "\n"
        (mapAttrsToList (n: v: ''cp -RTfpv "$indir/"${v} "$outdir/"'') target.targets)}

      # Launch custom script
      ${optionalString (target.restoreScript != "") target.restoreScript}

      # Resume services
      ${concatStringSep "\n" (map (s: "systemctl start ${s}") target.suspendServices)}
    '';

    backupBin = writeShellScriptBin "hey-backup" ''
      if [[ $1 ]]; then
        if [[ ! -x ${cfg.path}/$1/backup.sh ]]; then
          >&2 echo "Could not find backup for #{name}. Aborting..."
          exit 1
        fi
        echo "Backing up $1"
        $i/backup.sh
      else
        echo "Backing up all targets"
        for i in ${cfg.path}/*; do
          echo "Backing up: $i"
          $i/backup.sh
        done
      fi
    '';

    restoreBin = writeShellScriptBin "hey-restore" ''
      if [[ ! -d ${cfg.path} || -z "$(ls -A ${cfg.path})" ]]; then
        >&2 echo "No backups on this system. Aborting..."
        exit 1
      fi
      if [[ $1 ]]; then
        if [[ ! -x ${cfg.path}/$1/restore.sh ]]; then
          >&2 echo "Could not find backup for #{name}. Aborting..."
          exit 1
        fi
        echo "Restoring $1"
        ${cfg.path}/$1/restore.sh
      else
        echo "Restoring all targets from latest backup"
        for i in ${cfg.path}/*; do
          echo "Restoring backup: $i"
        done
      fi
    '';
in {
  options.modules.backup = with types; {
    enable         = mkBoolOpt false;
    path           = mkOpt (either path str) "/run/backups";
    targets        = mkOpt (attrsOf backupType) {};
    schedule       = mkOpt str "";   # e.g. "02:00"
    maxGenerations = mkOpt int 5;
  };

  config = mkIf (cfg.enable && cfg.targets != {}) {
    users.users.backup = {
      description = "The nixos backup service";
      group = "backup";
      home = cfg.path;
      isSystemUser = true;
      useDefaultShell = true;
    };
    users.groups.backup = {};


    system.activationScripts.backupInit = ''
      echo "Generating backup files"
      BASEDIR="${cfg.path}"
      mkdir -p "$BASEDIR"
      chown backup:backup "$BASEDIR"
      chmod 700 "$BASEDIR"
      ${concatStringSep "\n" (mapAttrsToList (n: v: ''
          echo "Generating backup dir: $BASEDIR"
          TARGETDIR="$BASEDIR/${v.name}"
          mkdir -p "$TARGETDIR"
          chown ${v.owner}:${v.group} "$TARGETDIR"
          chmod ${v.mode} "$TARGETDIR"
          cp -f ${targetBackupScript v}/bin/backup.sh "$TARGETDIR/backup.sh"
          cp -f ${targetRestoreScript v}/bin/restore.sh "$TARGETDIR/restore.sh"
          chmod 700 {backup,restore}.sh
        '') cfg.targets)}
      echo "Generated backup files!"
    '';


    systemd.services.hey-backups = {
      description = "Backup system";
      environment.TARGET_DIR = cfg.path;
      serviceConfig = {
        SyslogIdentifier = "hey-backups";
        Type = "oneshot";
        User = mkDefault user;
        Group = mkDefault group;
        ExecStart = "${pkgs.bash}/bin/bash ${backupBin}/bin/hey-backup";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.timers.hey-backups = mkIf (cfg.schedule != "") {
      description = "Backup dotfile targets on time";
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = "true";
        Unit = "hey-backups.service";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Add 'bin/hey backup' extensions to PATH
    environment.systemPackages = [
      backupBin
      restoreBin
    ];
  };
}
