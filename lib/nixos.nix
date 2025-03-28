# lib/flakes.nix --- syntax sugar for flakes
#
# This may look a lot like what flake-parts, flake-utils(-plus), and/or digga
# offer. I reinvent the wheel because (besides flake-utils), they are too
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

  # FIXME: Refactor me! (Use submodules?)
  mkFlake = {
    self
    , hey ? self
    , nixpkgs ? hey.inputs.nixpkgs
    , nixpkgs-unstable ? hey.inputs.nixpkgs-unstable or hey.inputs.nixpkgs-unstable or nixpkgs
    , disko ? hey.inputs.disko
    , ...
  } @ inputs: {
    apps ? {}
    , checks ? {}
    , devShells ? {}
    , hosts ? {}
    , modules ? {}
    , overlays ? {}
    , packages ? {}
    , storage ? {}
    , systems
    , templates ? {}
    , ...
  } @ flake:
    let
      mkPkgs = system: pkgs: overlays: import pkgs {
        inherit system overlays;
        config.allowUnfree = true;
        # A number of packages depend on python 2.7, but nixpkgs errors out when
        # it is pulled, so...
        config.permittedInsecurePackages = [ "python-2.7.18.6" ];
      };

      # Processes external arguments that bin/hey will feed to this flake (using
      # a json payload in an envvar). The internal var is kept in lib to stop
      # 'nix flake check' from complaining more than it has to.
      args =
        let hargs = getEnv "HEYENV"; in
        if hargs == ""
        then abort "HEYENV envvar is missing"
        else fromJSON hargs;

      # This is the only impurity we allow into this flake, because there are
      # many times where it is more convenient to generate or seed dotfiles or
      # envvars with local (non-nix-store) paths instead, so I don't have to
      # rebuild each time I change/swap them out.
      nixosConfigurations = mapAttrs (hostName: { path, config }:
        # TODO: Replace with a submodule
        let
          nixosModules =
            filterMapAttrs
              (_: i: i ? nixosModules)
              (_: i: i.nixosModules)
              inputs;
          mkDotfiles = dir: {
            dir =
              if dir != "" then dir
              else abort "No or invalid dir specified: ${dir}";
            binDir      = "${dir}/bin";
            libDir      = "${dir}/lib";
            configDir   = "${dir}/config";
            modulesDir  = "${dir}/modules";
            themesDir   = "${dir}/modules/themes";
            hostDir     = "${path}";
          };
          mkModules = filterMapAttrs
            (_: i: i ? nixosModules)
            (_: i: i.nixosModules);
          mkSelf = system:
            self // {
              inherit args;
              modules = mkModules self.inputs;
              packages = self.packages.${system};
              devShell = self.devShell.${system};
              apps = self.apps.${host.system};
            } // (mkDotfiles (toString self));
          mkHey = system:
            hey // {
              inherit args;
              modules = mkModules hey.inputs;
              packages = hey.packages.${system};
              devShell = hey.devShell.${system};
              apps = hey.apps.${system};
            } // (mkDotfiles args.path);

          self' = mkSelf host.system;
          hey' = mkHey host.system;
          host = config {
            inherit args lib nixosModules;
            hey = hey';
          };
          pkgs = mkPkgs host.system nixpkgs ((attrValues overlays) ++ [
            (final: prev: {
              unstable = mkPkgs host.system nixpkgs-unstable (attrValues overlays);
            })
          ]);
        in
          nixpkgs.lib.nixosSystem {
            system = host.system;
            specialArgs.self = self';
            specialArgs.hey = hey';
            modules = [
              disko.nixosModules.disko
              (if isFunction storage
               then (attrs: { disko.devices = storage attrs; })
               else { disko.devices = storage; })
              {
                nixpkgs.pkgs = pkgs;
                networking.hostName = mkDefault (args.host or hostName);
              }
              ../.
            ]
            ++ (host.imports or [])
            ++ [ {
              modules = host.modules or {};
              # theme = host.theme or {};
            } ]
            ++ [ (host.config or {}) (host.hardware or {}) ];
          }) hosts;
      perSystem = map (system:
        let withPkgs = pkgs: packageAttrs:
              mapFilterAttrs
                (_: v: pkgs.callPackage v { self = self.packages.${system}; })
                (_: v: !(v ? meta.platforms) || (elem system v.meta.platforms))
                packageAttrs;
            pkgs = mkPkgs system nixpkgs (attrValues overlays);
        in filterAttrs (_: v: v.${system} != {}) {
          apps.${system} = apps;
          checks.${system} = withPkgs pkgs checks;
          devShells.${system} = withPkgs pkgs devShells;
          packages.${system} = withPkgs pkgs packages;
        }) systems;
    in
      (filterAttrs (n: _: !elem n [
        "apps" "bundlers" "checks" "devices" "devShells" "hosts" "modules"
        "packages" "storage" "systems"
      ]) flake) // {
          inherit nixosConfigurations;
          nixosModules = modules;

          # To parameterize this flake (more so for flakes derived from this
          # one) I rely on bin/hey (my nix{,os} CLI/wrapper) to emulate
          # --arg/--argstr options. 'dir' and 'host' are special though, and
          # communicated using hey's -f/--flake and --host options:
          #
          #   hey sync -f /etc/nixos#soba
          #   hey sync -f /etc/nixos --host soba
          #
          # The magic that allows this lives in mkFlake, but requires --impure
          # mode. Sorry hermetic purists!
          _heyArgs = args;
      } // (mergeAttrs' perSystem);
}
