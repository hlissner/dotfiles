{ config, options, lib, home-manager, ... }:

with lib;
with lib.my;
{
  options = {
    user = mkOpt types.attrs {};

    home = with types; {
      file       = mkOpt' attrs {} "Files to place directly in $HOME";
      configFile = mkOpt' attrs {} "Files to place in $XDG_CONFIG_HOME";
      dataFile   = mkOpt' attrs {} "Files to place in $XDG_DATA_HOME";
    };

    env = mkOption {
      type = with types; attrsOf (oneOf [ str path (listOf (either str path)) ]);
      apply = mapAttrs
        (n: v: if isList v
               then concatMapStringsSep ":" (x: toString x) v
               else (toString v));
      default = {};
      description = "TODO";
    };
  };

  config = {
    user = {
      description = "The primary user account";
      extraGroups = [ "wheel" ];
      isNormalUser = true;
      name = let name = builtins.getEnv "USER"; in
             if elem name [ "" "root" ]
             then "hlissner" else name;
      uid = 1000;
    };

    # Install user packages to /etc/profiles instead. Necessary for
    # nixos-rebuild build-vm to work.
    home-manager = {
      useUserPackages = true;

      # I only need a subset of home-manager's capabilities. That is, access to
      # its home.file, home.xdg.configFile and home.xdg.dataFile so I can deploy
      # files easily to my $HOME, but 'home-manager.users.hlissner.home.file.*'
      # is much too long and harder to maintain, so I've made aliases in:
      #
      #   home.file        ->  home-manager.users.hlissner.home.file
      #   home.configFile  ->  home-manager.users.hlissner.home.xdg.configFile
      #   home.dataFile    ->  home-manager.users.hlissner.home.xdg.dataFile
      users.${config.user.name} = {
        home = {
          file = mkAliasDefinitions options.home.file;
          # Necessary for home-manager to work with flakes, otherwise it will
          # look for a nixpkgs channel.
          stateVersion = config.system.stateVersion;
        };
        xdg = {
          configFile = mkAliasDefinitions options.home.configFile;
          dataFile   = mkAliasDefinitions options.home.dataFile;
        };
      };
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    nix = let users = [ "root" config.user.name ]; in {
      trustedUsers = users;
      allowedUsers = users;
    };

    # must already begin with pre-existing PATH. Also, can't use binDir here,
    # because it contains a nix store path.
    env.PATH = [ binDir "$PATH" ];

    environment.extraInit =
      concatStringsSep "\n"
        (mapAttrsToList (n: v: "export ${n}=\"${v}\"") config.env);
  };
}
