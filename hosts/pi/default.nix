# Pi -- a Raspberry Pi 3 B printer server

{ self, lib, ... }:

with lib;
with builtins;
{
  system = "aarch64-linux";

  imports = [
    # The 64-bit vendor kernel Pi OS ships for the whole BCM2710 family (3B,
    # 3B+, Zero 2 W, etc).
    self.modules.nixos-hardware.raspberry-pi-3
  ];

  modules = {
    profiles = {
      role = "server";
      user = "hlissner";
      networks = [ "ca" ];
      hardware = [ "wifi" "printer/share" ];
    };

    shell.zsh.enable = true;
    services.ssh.enable = true;
  };

  config = { config, pkgs, ... }: {
    # The M28 speaks PCLm and IPP-over-USB, so ipp-usb turns it into a local IPP
    # everywhere printer and CUPS needs no driver at all. HPLIP would do (no
    # plugin needed, says its models.dat), but drags python and qt onto a box
    # with limited ram.
    services.ipp-usb.enable = true;
    # ipp-usb handles the scanner in the MFP.
    hardware.sane.enable = false;

    # `-m everywhere` asks the printer for its capabilities, so the queue is
    # provisioned by ensure-printers, which follows ipp-usb: plugging the
    # printer in is enough. `systemctl restart ensure-printers` if it isn't.
    hardware.printers = {
      ensurePrinters = [{
        name = "LaserJet";
        description = "HP LaserJet MFP M28-M31";
        location = "Home";
        deviceUri = "ipp://localhost:60000/ipp/print";
        model = "everywhere";
      }];
      ensureDefaultPrinter = "LaserJet";
    };

    # The card is the slowest and most mortal thing on this box, so nothing
    # routine gets written to it. Logs live in RAM and die with a reboot.
    services.journald.settings.Journal = {
      Storage = "volatile";
      RuntimeMaxUse = "32M";
    };
    services.printing.logLevel = "warn";  # info narrates every IPP request
    systemd.coredump.settings.Coredump.Storage = "none";

    # Deduping means reading back, hashing, and relinking every path
    nix.settings.auto-optimise-store = mkForce false;

    # Nothing gets built here: 1GB can't evaluate nixpkgs, let alone compile.
    # Use `hey ops push pi` to build on udon and transfer the closure over.
    nix.settings.max-jobs = 0;
  };

  hardware = { config, pkgs, modulesPath, ... }: {
    imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

    sdImage = {
      compressImage = false;  # it gets dd'd right away; zstd only costs minutes
      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
          -c ${config.system.build.toplevel} -d ./files/boot
      '';
    };

    # nixos-hardware stages the GPU blobs, u-boot and config.txt onto the
    # firmware partition, both into the image and on every switch.
    hardware.raspberry-pi.firmware = {
      enable = true;
      uboot.enable = true;
    };

    # Headless, so the profile's Pi OS defaults (KMS, camera and display
    # probing, the LEDs) are all drain. The 3B's power LED is on a GPIO too.
    hardware.raspberry-pi.configtxt = {
      settings.all = {
        camera_auto_detect = false;
        display_auto_detect = false;
        max_framebuffers = null;
        gpu_mem = 16;
        dtparam = [ "act_led_trigger=none" "pwr_led_trigger=none" ];
      };
      # Replaces the vc4-kms-v3d default. Bluetooth shares the wifi chip and
      # its UART; off it goes.
      deviceTreeOverlays.all = [ { disable-bt = {}; } ];
    };

    fileSystems."/".options = [ "noatime" "commit=120" ];

    swapDevices = [];
  };
}
