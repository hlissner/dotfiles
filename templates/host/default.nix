# {hostname} -- {short description of this host's purpose}

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  # Import any nixos-hardware modules here, e.g.
  imports = [
    # self.modules.nixos-hardware.dell-xps-13-9370
  ];

  modules = {
    profiles = {
      role = "workstation";  # or "server"
      # user = "NAME";       # loads modules/profiles/user/NAME.nix, once there is one
      # platform = "linode"; # modules/profiles/platform/
      # networks = [ "ca" "dk" "ts0" ];  # modules/profiles/networks/
      hardware = [           # modules/profiles/hardware/; the slashes are matched by prefix
        "cpu/intel"          # cpu/intel/{kaby-lake,sandy-bridge}, cpu/amd, cpu/amd/raphael
        # "gpu/nvidia"       # gpu/nvidia/{kepler,pascal,turing}
        # "pc/laptop"
        "audio"              # audio/realtime for DAW work
        # "bluetooth"
        "ssd"
        # "wifi"
        # "hidpi"
        # "printer"          # printer/share serves it to the LAN, printer/wireless finds one
        # "scanner"
        # "wacom"
        # "ergodox"
        # "razer"
        # "vr"
      ];
    };

    wm = {
      desktop = "niri";  # or null for a headless machine; enables modules.wm.niri
      niri = {
        monitors = [
          # At least one monitor (with primary = true) is required
          { output = "DP-1";              # a connector or "Make Model Serial"
            primary = true;               # home workspace opens here
            # mode = "2560x1440@144.000";   # "WxH" or "WxH@Hz", Hz to three decimals
            # position = { x = 0; y = 0; }; # logical pixels; null lets niri place it
            # scale = 1.0;
            # transform = "normal";         # 90, 180, 270, flipped, flipped-90, ...
            # vrr = false;                  # true, or "on-demand"
            # off = false;
            # backdropColor = null;
            # hotCorners = null;            # null inherits; [] is off
            # layout = "";                  # raw KDL for this output's layout {}
            # extraConfig = "";             # raw KDL for anything else (modelines)
          }
        ];
        # extraConfig = "";                 # KDL appended to config.kdl
      };
      plymouth = {
        enable = true;
        # theme = "nixos-bgrt";             # must be shipped by one of themePackages
        # themePackages = [ pkgs.nixos-bgrt-plymouth ];
        # logo = ./logo.png;                # for themes that take one
        # quiet = true;                     # silence kernel/initrd/udev output
        # seamless = false;                 # hold the last frame until the compositor paints
        # nvidia = <true if any gpu/nvidia profile>;  # nvidia DRM in the initrd
      };
      # noctalia = {
      #   settings = {};                    # TOML; above config/noctalia/, below the GUI
      #   plugins."author/plugin" = { enable = true; src = null; };
      # };
      # theme = {
      #   fonts = {
      #     mono = "JetBrainsMono Nerd Font";
      #     sans = "Fira Sans";
      #     packages = [ ... ];             # must ship both of the above
      #   };
      #   cursor = {
      #     name = "catppuccin-mocha-dark-cursors";
      #     package = pkgs.catppuccin-cursors.mochaDark;
      #     size = 32;
      #   };
      #   icons = { name = "Dracula"; packages = [ ... ]; };
      #   colors = {};                      # seed colors: "#hex" or { color; blend = true; }
      #   builtinTemplates = [];            # Noctalia template ids
      #   communityTemplates = [];
      #   files = {};                       # { input_path; output_path; pre_hook; post_hook; }
      # };
    };

    apps = {
      term.default = "foot";  # default: "xterm"
      term.foot.enable = true;
      # term.foot.fontSize = 9;
      rofi.enable = true;
      browsers.default = "librewolf";  # default: null
      browsers.librewolf = {
        enable = true;
        # profileName = config.user.name;
        # settings = {};        # user.js preferences
        # extraConfig = "";     # raw user.js lines
        # policies = {};        # policies.json
        # extensions = {};      # ExtensionSettings, by extension id
        # userChrome = "";
        # userContent = "";
        # beval.enable = false;
      };
      # thunar.enable = false;
      # flatpak.enable = false;
      # libreoffice.enable = false;
      # godot.enable = false;
      # lutris.enable = false;
      # feishin.enable = false;
      # supersonic.enable = false;
      # media = {
      #   cad = { enable = false; cudaSupport = false; };
      #   daw.enable = false;
      #   graphics = {              # enable turns on all of these
      #     enable = false;
      #     design.enable = false;
      #     raster.enable = false;
      #     sprites.enable = false;
      #     tools.enable = false;
      #     vector.enable = false;
      #   };
      #   music.enable = false;
      #   pdf.enable = false;
      #   video = {
      #     enable = false;
      #     capture.enable = false;
      #     editor.enable = false;
      #     player.enable = false;
      #     tools.enable = false;
      #   };
      # };
    };

    editors = {
      default = "nvim";  # default: "vim"
      vim.enable = true;
      # emacs.enable = false;
    };

    shell = {
      git.enable = true;
      tmux.enable = true;
      # tmux.term = "xterm-256color";
      # tmux.rcFiles = [];
      zsh = {
        enable = true;
        # envFiles = [];  # sourced by zshenv
        # envInit = "";   # lines appended to it
        # rcFiles = [];   # sourced by zshrc
        # rcInit = "";
      };
      # direnv.enable = false;
      # gnupg = { enable = false; cacheTTL = 3600; };
      # vaultwarden = { enable = false; settings = {}; };  # rbw config
      # yazi = { enable = false; extraPackages = []; };
      # zellij = { enable = false; zmate.enable = false; };
    };

    # dev = {
    #   cc.enable = false;
    #   clojure.enable = false;
    #   common-lisp.enable = false;
    #   java.enable = false;
    #   lua = { enable = false; fennel.enable = false; love2D.enable = false; };
    #   node.enable = false;
    #   python.enable = false;
    #   ruby.enable = false;
    #   rust.enable = false;
    #   scala.enable = false;
    #   shell.enable = false;
    # };

    # games = {
    #   steam = {
    #     enable = false;
    #     libraryDir = "${config.home.dataDir}/Steam";
    #   };
    #   doom = {
    #     enable = false;
    #     iwad = "${steam.libraryDir}/steamapps/common/Doom 2/base/DOOM2.WAD";
    #     wadsDir = "${config.home.dataDir}/games/doom";
    #   };
    #   emulators = {
    #     enable = false;
    #     dataDir = "${config.home.dataDir}/es-de";
    #     romsDir = "";             # or systems.NAME.path, per system
    #     biosDir = "";             # defaults to bios/ beside each system's roms
    #     systems = {               # ES-DE's names; {} takes the defaults
    #       snes = {};
    #       psx.path = "/media/roms/psx";
    #       # per system: path, bios, core (retroarch), command (standalone)
    #     };
    #     retroarch = {
    #       enable = false;
    #       cores = [];             # on top of what systems.* ask for
    #       settings = {};          # retroarch.cfg
    #     };
    #   };
    # };

    services = {
      ssh.enable = true;
      # gnome-keyring.enable = false;
      # guix.enable = false;
    };

    system = {
      utils.enable = true;
      # utils.benchmarks.enable = false;
      # fs = {
      #   enable = true;
      #   nfs.enable = false;
      #   zfs.enable = <true if any fileSystems.*.fsType == "zfs">;
      # };
    };

    # virt = {
    #   docker.enable = false;
    #   lxd.enable = false;
    #   qemu.enable = false;
    # };

    # ai = {
    #   enable = false;
    #   aichat = { enable = false; openrouterKeyFile = null; };
    #   claude = { enable = false; settings = {}; };  # managed-settings.json
    # };

    # xdg = {
    #   enable = true;        # respect XDG everywhere
    #   ssh.enable = false;   # ~/.config/ssh instead of ~/.ssh
    # };
  };

  ## local config
  config = { config, pkgs, ... }: {
    user.name = "CHANGEME";  # needed if not set by a user profile
  };

  hardware = { ... }: {
    # By the labels mkfs gave them; README.md walks through partitioning.
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        options = [ "noatime" ];
      };
      "/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };
    };
    swapDevices = [];
  };
}
