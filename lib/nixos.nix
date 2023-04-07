# lib/flakes.nix --- syntax sugar for flakes
#
# This may look a lot like what flake-parts, flake-utils(-plus), and/or digga
# offer. I reinvent the whell because (besides flake-utils), they are too
# volatile to depend on. They see subtle and unannounced changes, often. Since I
# rely on this flake as a basis for 100+ systems, VMs, and containers, some of
# whom are mission-critical, I'd rather have a less polished API that I fully
# control than a robust one that I cannot predict, for maximum mobility. It's
# also a more valuable learning experience.

{ self, lib, attrs, modules }:

with builtins;
with lib;
with attrs;
with modules;
rec {
  mkApp = program: {
    inherit program;
    type = "app";
  };

  getProfileName = p: p._profile.name;
  getProfilePath = p: p._profile.path;

  # FIXME: Rushed. Refactor me
  mkProfiles = parentPath: dir:
    setAttrByPath parentPath
      (let readFilesRec = dir: fn:
             mapFilterAttrs'
               (n: v:
                 let path = "${dir}/${n}";
                 in if v == "directory"
                    then nameValuePair n (readFilesRec path fn)
                    else if v == "regular" && hasSuffix ".nix" n && !(hasPrefix "_" n)
                    then (if n == "default.nix"
                          then nameValuePair "_profile" (fn path true)
                          else nameValuePair (removeSuffix ".nix" n) {
                            _profile = fn path false;
                          })
                    else nameValuePair "" {})
               (_: v: v != {})
               (readDir dir);
       in readFilesRec dir (file: isDefault: {
         name =
           concatStringsSep "/"
             (parentPath ++ filter (s: s != "")
               (splitString "/"
                 (removePrefix "${dir}"
                   (removeSuffix (if isDefault then "/default.nix" else ".nix")
                     file))));
         path = file;
       }));

  # FIXME: Refactor me! (Use submodules)
  mkFlake = {
    self
    , super ? {}
    , nixpkgs ? self.inputs.nixpkgs or super.inputs.nixpkgs
    , nixpkgs-unstable ? self.inputs.nixpkgs-unstable or super.inputs.nixpkgs-unstable or nixpkgs
    # , disko ? self.inputs.disko
    , ...
  } @ inputs: {
    apps ? {}
    , checks ? {}
    , devShells ? {}
    , hosts ? {}
    , modules ? {}
    , overlays ? {}
    , packages ? {}
    , profiles ? {}
    , storage ? {}
    , systems
    , templates ? {}
    , ...
  } @ flake:
    let
      mkPkgs = system: pkgs: overlays: import pkgs {
        inherit system overlays;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [ "python-2.7.18.6" ];
      };

      # Inherited properties
      profiles' = mergeAttrs' [ (super.profiles or {}) profiles ];
      overlays' = (super.overlays or {}) // overlays;

      # Processes external arguments that bin/hey will feed to this flake (using
      # a json payload in an envvar). The internal var is kept in lib to stop
      # 'nix flake check' from complaining more than it has to.
      args =
        let args = getEnv "__HEYARGS"; in
        if args == "" then {} else fromJSON args;

      # This is the only impurity we allow into this flake, because there are
      # many times where it is more convenient to generate or seed dotfiles or
      # envvars with local (non-nix-store) paths instead, so I don't have to
      # rebuild each time I change/swap them out.
      nixosConfigurations = mapAttrs (hostName: cfg:
        # TODO: Replace with a submodule
        let
          self' = self // { inherit super; };
          nixosModules =
            filterMapAttrs
              (_: i: i ? nixosModules && i.nixosModules != {})
              (_: i: i.nixosModules)
              inputs;
          host = cfg {
            inherit args lib nixosModules;
            self = self';
            profiles = profiles';
          };
          mkDotfiles = path: {
            dir =
              if path != "" then path
              else abort "No or invalid dotfilesDir specified: ${path}";
            binDir      = "${path}/bin";
            configDir   = "${path}/config";
            modulesDir  = "${path}/modules";
            themesDir   = "${path}/modules/themes";
            hostDir     = "${path}/hosts/${hostName}";
          };
          pkgs = mkPkgs host.system nixpkgs ((attrValues overlays') ++ [
            (final: prev: {
              unstable = mkPkgs host.system nixpkgs-unstable (attrValues overlays');
            })
          ]);
        in
          nixpkgs.lib.nixosSystem {
            system = host.system;
            specialArgs.self = self' // {
              inherit args;
              modules = nixosModules;
              packages = self.packages.${host.system};
              devShell = self.devShell.${host.system};
              apps = self.apps.${host.system};
              store = mkDotfiles "${self}";
            } // (mkDotfiles (args.dir or "/etc/nixos"));
            modules = [
              # TODO: self.inputs.disko.nixosModules.disko
              # (if isFunction storage
              #  then (attrs: { disko.devices = storage attrs; })
              #  else { disko.devices = storage; })
              {
                nixpkgs.pkgs = pkgs;
                networking.hostName = mkDefault (args.host or hostName);
                profiles.active = map getProfileName (host.profiles or []);
              }
              (super.modules.default or {})
              (modules.default or {})
            ]
            ++ (host.imports or [])
            ++ (map getProfilePath (host.profiles or []))
            ++ [ { modules = host.modules or {}; } ]
            ++ [ (host.config or {}) (host.hardware or {}) ]
            ;
          }) hosts;
      perSystem = map (system:
        let withPkgs = pkgs: packageAttrs:
              mapFilterAttrs
                (_: v: pkgs.callPackage v { inherit self; })
                (_: v: !(v ? meta.platforms) || (elem system v.meta.platforms))
                packageAttrs;
            pkgs = mkPkgs system nixpkgs (attrValues overlays');
        in filterAttrs (_: v: v.${system} != {}) {
          apps.${system} = apps;
          checks.${system} = withPkgs pkgs checks;
          devShells.${system} = withPkgs pkgs devShells;
          packages.${system} = withPkgs pkgs packages;
        }) systems;
    in
      (filterAttrs (n: _: !elem n [
        "apps" "bundlers" "checks" "devices" "devShells" "hosts" "modules"
        "packages" "profiles" "storage" "systems"
      ]) flake) // {
          inherit nixosConfigurations;
          nixosModules = modules // { inherit profiles; };

          # To parameterize this flake (more so for flakes derived from this one)
          # I rely on bin/hey (my nix{,os} CLI/wrapper) to emulate --arg/--argstr
          # options. 'dir' and 'host' are special though, and communicated using
          # hey's -f/--flake and --host options:
          #
          #   hey rebuild -f /etc/nixos#soba
          #   hey rebuild -f /etc/nixos --host soba
          #
          # The magic that allows this lives in mkFlake, but requires --impure
          # mode. Sorry hermetic purists!
          _heyArgs = args;
      } // (mergeAttrs' perSystem);
}
