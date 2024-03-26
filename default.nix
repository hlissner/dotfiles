# default.nix

{ self, lib, options, config, pkgs, ... }:

with lib;
with self.lib;
let inherit (self) dir binDir configDir themesDir hostDir inputs;
in {
  imports = mapModulesRec' ./modules import;

  options = with types; {
    modules = {};

    # Creates a simpler, polymorphic alias for users.users.$USER.
    user = mkOpt attrs { name = ""; };

    # Creates a simpler alias for environment.variables, with a more predictable
    # load-order, since it will be used *a lot*.
    env = mkOption {
      type = attrsOf (oneOf [ str path (listOf (either str path)) ]);
      apply = mapAttrs
        (n: v: if isList v
               then "${concatMapStringsSep ":" (x: toString x) v}:\$${n}"
               else toString v);
      default = {};
      description = "TODO";
    };
  };

  config = {
    environment.extraInit = ''
      export DOTFILES_HOME="${dir}"
      export DOTFILES_BIN_HOME="${binDir}"
      export DOTFILES_LIB_HOME="${dir}/lib"
      export DOTFILES_CONFIG_HOME="${configDir}";
      export PATH="$DOTFILES_BIN_HOME:$PATH"
      ${concatStringsSep "\n"
        (mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.env)}
    '';

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
    # This is here to appease 'nix flake check' for generic hosts with no
    # hardware-configuration.nix or fileSystem config.
    fileSystems."/".device = mkDefault "/dev/disk/by-label/nixos";


    ## Nix core configuration
    nix =
      let filteredInputs = filterAttrs (_: v: v ? outputs) inputs;
          nixPathInputs  = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
      in {
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
        settings = {
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          auto-optimise-store = true;
          trusted-users = [ "root" config.user.name ];
          allowed-users = [ "root" config.user.name ];
        };
      };

    system = {
      configurationRevision = with inputs; mkIf (self ? rev) self.rev;
      stateVersion = "23.05";
    };

    boot = {
      # Prefer the latest kernel; this will be overridden on more security
      # conscious systems, among other settings in modules/security.nix.
      kernelPackages = mkDefault pkgs.unstable.linuxKernel.packages.linux_6_8;
      loader = {
        efi.canTouchEfiVariables = mkDefault true;
        # To not overwhelm the boot screen.
        systemd-boot.configurationLimit = mkDefault 10;
      };
    };


    ## Core, universal configuration for all NixOS machines.
    # Forgive me Stallman-senpai.
    env.NIXPKGS_ALLOW_UNFREE = "1";  # for nix-env
    # For unfree drivers/firmware my laptops/refurbed systems are likely to have.
    hardware.enableRedistributableFirmware = true;
    # Core shell utilities I need absolutely everywhere.
    environment.systemPackages = with pkgs; [
      cached-nix-shell
      bind
      git
      wget
    ];

    ## Extra support for bin/hey
    # For 'hey build-vm'
    virtualisation.vmVariant.virtualisation = {
      memorySize = 2048;  # default: 1024
      cores = 2;          # default: 1
    };
  };
}
