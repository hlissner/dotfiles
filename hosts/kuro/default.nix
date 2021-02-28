{ pkgs, config, ... }:
{
  imports = [
    ../home.nix
    ./hardware-configuration.nix
  ];

  ## Modules
  modules = {
    desktop = {
      bspwm.enable = true;
      apps = {
        discord.enable = true;
        rofi.enable = true;
        # godot.enable = true;
        signal.enable = true;
      };
      browsers = {
        default = "brave";
        brave.enable = true;
        firefox.enable = true;
        qutebrowser.enable = true;
      };
      gaming = {
        steam.enable = true;
        # emulators.enable = true;
        # emulators.psx.enable = true;
      };
      media = {
        daw.enable = true;
        documents.enable = true;
        graphics.enable = true;
        mpv.enable = true;
        recording.enable = true;
        spotify.enable = true;
      };
      term = {
        default = "xst";
        st.enable = true;
      };
      vm = {
        qemu.enable = true;
      };
    };
    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };
    shell = {
      adl.enable = true;
      bitwarden.enable = true;
      direnv.enable = true;
      git.enable    = true;
      gnupg.enable  = true;
      tmux.enable   = true;
      zsh.enable    = true;
    };
    services = {
      ssh.enable = true;
      # Needed occasionally to help the parental units with PC problems
      # teamviewer.enable = true;
    };
    theme.active = "alucard";
  };


  ## Local config
  programs.ssh.startAgent = true;
  services.openssh.startWhenNeeded = true;

  networking.networkmanager.enable = true;
  # The global useDHCP flag is deprecated, therefore explicitly set to false
  # here. Per-interface useDHCP will be mandatory in the future, so this
  # generated config replicates the default behaviour.
  networking.useDHCP = false;


  ## Backups
  systemd = {
    services.backups = {
      description = "Back up personal files";
      wants = [ "usr-drive.mount" ];
      path  = [ pkgs.rsync ];
      environment = {
        SRC_DIR  = "/usr/store";
        DEST_DIR = "/usr/drive";
      };
      script = ''
        rcp() {
          if [[ -d "$1" && -d "$2" ]]; then
            echo "---- BACKUPING UP $1 TO $2 ----"
            rsync -rlptPJ --delete --delete-after \
                --include=.git/ \
                --filter=':- .gitignore' \
                --filter=':- $XDG_CONFIG_HOME/git/ignore' \
                --chmod=go= \
                "$1" "$2"
          fi
        }
        rcp "$HOME/projects/" "$SRC_DIR/projects"
        pushd "$SRC_DIR"
        for dirname in *; do
          rcp "$SRC_DIR/$dirname/" "$DEST_DIR/$dirname"
        done
      '';
      serviceConfig = {
        Type = "oneshot";
        Nice = 19;
        IOSchedulingClass = "idle";
        User = config.user.name;
        Group = "users";
      };
    };
    timers.backup = {
      wantedBy = [ "timers.target" ];
      partOf = [ "backups.service" ];
      timerConfig.OnCalendar = "8/2"; # every 4h from 8am
    };
  };
}
