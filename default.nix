{ inputs, config, options, lib, pkgs, ... }:

with lib;
with lib.my;

let dotfilesDir = removePrefix "/mnt" (builtins.getEnv "DOTFILES");
    user = builtins.getEnv "USER";
in {
  imports =
    # I use home-manager to deploy files to $HOME; little else
    [ inputs.home-manager.nixosModules.home-manager ]
    # All my personal modules
    ++ (mapModulesRec' (toString ./modules) import);

  options = with types; {
    dotfiles = {
      dir = mkOpt path dotfilesDir;
      binDir     = mkOpt path "${config.dotfiles.dir}/bin";
      configDir  = mkOpt path "${config.dotfiles.dir}/config";
      modulesDir = mkOpt path "${config.dotfiles.dir}/modules";
      themesDir  = mkOpt path "${config.dotfiles.modulesDir}/themes";
    };

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

    # Creates a simpler, polymorphic alias for users.users.$USER.
    user = mkOpt attrs {};
  };

  config = {
    assertions = [
      {
        assertion = pathIsDirectory dotfilesDir;
        message = "$DOTFILES is missing. It must be set to the location of your dotfiles.";
      }
      {
        assertion = user
        message = "$USER is missing. It must be set to the user you want.";
      }
      {
        assertion = user != "root"
        message = "$USER cannot be root. Set it to the user you want.";
      }
    ];


    ## Bootstrap this config's core options
    user =
      let name = if elem user [ "" "root" ] then (builtins.getEnv "USER") else user;
      in {
        inherit name;
        description = "The primary user account";
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        home = "/home/${name}";
        group = "users";
        uid = 1000;
      };
    users.users.${config.user.name} = mkAliasDefinitions options.user;

    environment.extraInit =
      concatStringsSep "\n"
        (mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.env);


    ## Core, universal configuration for all NixOS machines.
    env.PATH = [ "$DOTFILES_BIN" "$XDG_BIN_HOME" "$PATH" ];
    env.DOTFILES = config.dotfiles.dir;
    env.DOTFILES_BIN = config.dotfiles.binDir;
    env.NIXPKGS_ALLOW_UNFREE = "1"; # Forgive me Stallman senpai

    hardware.enableRedistributableFirmware = true;
    nix =
      let filteredInputs = filterAttrs (n: _: n != "self") inputs;
          nixPathInputs  = mapAttrsToList (n: v: "${n}=${v}") filteredInputs;
          registryInputs = mapAttrs (_: v: { flake = v; }) filteredInputs;
      in {
        package = pkgs.nixFlakes;
        extraOptions = "experimental-features = nix-command flakes";
        nixPath = nixPathInputs ++ [
          "nixpkgs-overlays=${config.dotfiles.dir}/overlays"
          "dotfiles=${config.dotfiles.dir}"
        ];
        registry = registryInputs // { dotfiles.flake = inputs.self; };
        settings = let users = [ "root" config.user.name ]; in {
          substituters = [
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          auto-optimise-store = true;
          trusted-users = users;
          allowed-users = users;
        };
      };
    system.configurationRevision = with inputs; mkIf (self ? rev) self.rev;
    system.stateVersion = "21.05";

    # Use the latest kernel
    boot = {
      kernelPackages = mkDefault pkgs.linuxKernel.packages.linux_6_0;
      loader = {
        efi.canTouchEfiVariables = mkDefault true;
        systemd-boot.configurationLimit = mkDefault 10;
      };
    };

    # Just the bear necessities...
    environment.systemPackages = with pkgs; [
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
  };
}
