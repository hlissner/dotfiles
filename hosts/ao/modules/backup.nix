{ config, lib, pkgs, ... }:

{
  services.bitwarden_rs.backupDir = "/backups/bitwarden_rs";
  services.gitea.dump.enable = true;
  services.gitea.dump.backupDir = "/backups/gitea";
  system.activationScripts.createBackupDir = ''
    mkdir -m 750 -p "${config.services.bitwarden_rs.backupDir}" || true
    mkdir -m 750 -p "${config.services.gitea.dump.backupDir}" || true
    chown bitwarden_rs:bitwarden_rs "${config.services.bitwarden_rs.backupDir}"
    chown git:gitea "${config.services.gitea.dump.backupDir}"
  '';

  # systemd = {
  #   services.backups = {
  #     description = "Backup /backups to NAS";
  #     wants = [ "usr-drive.mount" ];
  #     path  = [ pkgs.rsync ];
  #     environment = {
  #       SRC_DIR  = "/backups";
  #       DEST_DIR = "/usr/drive";
  #     };
  #     script = ''
  #       if [[ -d "$1" && -d "$2" ]]; then
  #         echo "---- BACKUPING UP $1 TO $2 ----"
  #         rsync -rlptPJ --delete --delete-after \
  #             --chmod=go= \
  #             --chown=hlissner:users \
  #             --exclude=lost+found/ \
  #             --exclude=@eaDir/ \
  #             --include=.git/ \
  #             --filter=':- .gitignore' \
  #             --filter=':- $XDG_CONFIG_HOME/git/ignore' \
  #             "$SRC_DIR/" "$DEST_DIR"
  #       fi
  #     '';
  #     serviceConfig = {
  #       Type = "oneshot";
  #       Nice = 19;
  #       IOSchedulingClass = "idle";
  #     };
  #   };
  #   timers.backups = {
  #     wantedBy = [ "timers.target" ];
  #     partOf = [ "backups.service" ];
  #     timerConfig.OnCalendar = "*-*-* 03:00:00";
  #     timerConfig.Persistent = true;
  #   };
  # };
}
