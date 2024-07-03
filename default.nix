# default.nix

{ hey, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
{
  imports = mapModulesRec' ./modules import;

  options = with types; {
    modules = {};

    # Creates a simpler, polymorphic alias for users.users.$USER.
    user = mkOpt attrs { name = ""; };
  };

  config = {
    assertions = [{
      assertion = config.user ? name;
      message = "config.user.name is not set!";
    }];

    environment.sessionVariables = mkOrder 10 {
      DOTFILES_HOME = hey.dir;
      NIXPKGS_ALLOW_UNFREE = "1";   # Forgive me Stallman-senpai.
    };

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

    nix =
      let filteredInputs = filterAttrs (_: v: v ? outputs) hey.inputs;
          nixPathInputs  = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
      in {
        extraOptions = ''
          warn-dirty = false
          http2 = true
          experimental-features = nix-command flakes
        '';
        nixPath = nixPathInputs ++ [
          "nixpkgs-overlays=${hey.dir}/overlays"
          "dotfiles=${hey.dir}"
        ];
        registry = mapAttrs (_: v: { flake = v; }) filteredInputs;
        settings = {
          substituters = [
            "https://nix-community.cachix.org"
            "https://hyprland.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          ];
          trusted-users = [ "root" config.user.name ];
          allowed-users = [ "root" config.user.name ];
          auto-optimise-store = true;
        };
      };

    system = {
      configurationRevision = with hey.inputs; mkIf (hey ? rev) hey.rev;
      stateVersion = "23.11";
    };

    boot = {
      # initrd.systemd.enable = true;
      # Prefer the latest kernel; this will be overridden on more security
      # conscious systems, among other settings in modules/security.nix.
      kernelPackages = mkDefault pkgs.unstable.linuxKernel.packages.linux_6_8;
      loader = {
        efi.canTouchEfiVariables = mkDefault true;
        # To not overwhelm the boot screen.
        systemd-boot.configurationLimit = mkDefault 10;
      };
    };

    # For unfree hardware my laptops/refurbed systems will likely have.
    hardware.enableRedistributableFirmware = true;

    # For `hey sync build-vm` (or `nixos-rebuild build-vm`)
    virtualisation.vmVariant.virtualisation = {
      memorySize = 2048;  # default: 1024
      cores = 2;          # default: 1
    };
  };
}
