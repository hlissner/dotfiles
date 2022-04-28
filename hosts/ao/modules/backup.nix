{ config, lib, pkgs, ... }:

{
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
