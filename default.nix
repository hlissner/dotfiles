{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let inherit (self) dir binDir inputs;
in {
  imports = mapModulesRec' ./modules import;

  options = with types; {
    # For keeping track of enabled profiles. Should not be modified by the user.
    profiles.active = mkOpt (listOf str) [];

    # Creates a simpler, polymorphic alias for users.users.$USER.
    user = mkOpt attrs { name = ""; };

    # Creates a simpler, more predictable alias for environment.variables,
    # because it's going to be used *a lot*.
    env = mkOption {
      type = attrsOf (oneOf [ str path (listOf (either str path)) ]);
      apply = mapAttrs
        (n: v: if isList v
               then concatMapStringsSep ":" (x: toString x) v
               else (toString v));
      default = {};
      description = "TODO";
    };

    modules = {};
  };

  config = {
    assertions = [
      {
        assertion = config.user ? name && config.user.name != "";
        message = "user.name is required, but not set.";
      }
      {
        assertion = config.user.name != "root";
        message = "user.name cannot be set to root.";
      }
    ];

    environment.extraInit =
      concatStringsSep "\n"
        (mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.env);

    # FIXME: Make this optional
    user = {
      description = mkDefault "The primary user account";
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      home = "/home/${config.user.name}";
      group = "users";
      uid = 1000;
    };
    users.users.${config.user.name} = mkAliasDefinitions options.user;

    ## Core, universal configuration for all NixOS machines.
    env.PATH = [ "$DOTFILES_BIN" "$XDG_BIN_HOME" "$PATH" ];
    env.DOTFILES = dir;
    env.DOTFILES_BIN = binDir;


    ## Core, universal configuration for all NixOS machines.
    # This is here to appease 'nix flake check' for generic hosts with no
    # hardware-configuration.nix or fileSystem config.
    fileSystems."/".device = mkDefault "/dev/disk/by-label/nixos";

    boot = {
      # Prefer the latest kernel; this will be overridden on more security
      # conscious systems, among other settings in modules/security.nix.
      kernelPackages = mkDefault pkgs.linuxKernel.packages.linux_6_1;
      loader = {
        efi.canTouchEfiVariables = mkDefault true;
        # To not overwhelm the boot screen.
        systemd-boot.configurationLimit = mkDefault 10;
        # For much quicker boot up to NixOS. I can use `systemctl reboot
        # --boot-loader-entry=X` instead.
        timeout = 1;
      };
    };

    environment.systemPackages = with pkgs; [
      bc
      bind
      cached-nix-shell
      git
      vim
      wget
      gnumake
      unzip
    ];

    # The global useDHCP flag is deprecated, therefore explicitly set to false
    # here. Per-interface useDHCP will be mandatory in the future, so we enforce
    # this default behavior here.
    networking.useDHCP = mkDefault false;


    ## Nix core configuration
    nix =
      let filteredInputs = filterAttrs (_: v: v ? outputs) inputs;
          nixPathInputs  = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
      in {
        package = pkgs.nixFlakes;
        extraOptions = ''
          warn-dirty = false
          http2 = true
          experimental-features = nix-command flakes
        '';
        nixPath = nixPathInputs ++ [
          "nixpkgs-overlays=${dir}/overlays"
          "dotfiles=${dir}"
        ];
        registry = mapAttrs (_: v: { flake = v; }) filteredInputs;
        settings = let users = [ "root" config.user.name ]; in {
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          auto-optimise-store = true;
          trusted-users = users;
          allowed-users = users;
        };
      };
    system = {
      configurationRevision = with inputs; mkIf (self ? rev) self.rev;
      stateVersion = "21.05";
    };

    # Forgive me Stallman-senpai.
    env.NIXPKGS_ALLOW_UNFREE = "1";  # for nix-env
    # For unfree drivers/firmware my laptops/refurbed systems are likely to have.
    hardware.enableRedistributableFirmware = true;

    # For build-vm
    virtualisation.vmVariant.virtualisation = {
      memorySize = 2048;  # default: 1024
      cores = 2;          # default: 1
    };
  };
}
