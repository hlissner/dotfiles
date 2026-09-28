# lib/nixos.nix --- syntax sugar for flakes
#
# This may look a lot like what flake-parts, flake-utils(-plus), and/or digga
# offer. I reinvent the wheel because (besides flake-utils), they are too
# volatile to depend on. They see subtle and unannounced changes, often. Since I
# rely on this flake as a basis for 100+ systems, VMs, and containers, some of
# whom are mission-critical, I'd rather have a less polished API that I fully
# control than a robust one that I cannot predict, for maximum mobility. It's
# also a more valuable learning experience.

{ lib }:

with builtins;
with lib;
rec {
  # nixosModulesOf :: attrs -> attrs
  nixosModulesOf = inputs:
    mapAttrs
      (_: i: i.nixosModules)
      (filterAttrs (_: i: i ? nixosModules) inputs);

  mkApp = program: {
    # A bare path fails 'nix flake check'; the app schema wants a string.
    program = toString program;
    type = "app";
  };

  # A flake as one system sees it: packages.${system}.foo -> packages.foo.
  forSystem = system: flake:
    flake // mapAttrs (_: v: v.${system} or {})
      (filterAttrs (n: _: elem n [ "packages" "legacyPackages" "devShells"
                                   "apps" "checks" "formatter" ]) flake);

  # The checkout's layout, rooted at DIR. `self` carries these over the store
  # snapshot; the live checkout's are the hey.{dir,*Dir} options in
  # modules/hey.nix, since that's the one a host may want somewhere else.
  dirsOf = dir: {
    inherit dir;
    binDir      = "${dir}/bin";
    libDir      = "${dir}/lib";
    configDir   = "${dir}/config";
    modulesDir  = "${dir}/modules";
  };

  mkHey = {
    flake
  , system
  , hostDir
  , heyLib ? flake.lib
  }:
    forSystem system flake // {
      inherit hostDir;
      lib = heyLib;
      inputs = mapAttrs (_: forSystem system) flake.inputs;
      modules = nixosModulesOf flake.inputs;
    };

  mkHostModules = {
    host
  , hostName
  , pkgs
  , extraModules ? []
  }: [
    {
      nixpkgs.pkgs = pkgs;
      networking.hostName = mkDefault hostName;
    }
    ../.
  ]
  ++ (host.imports or [])
  ++ [
    { modules = host.modules or {}; }
    (host.config or {})
    (host.hardware or {})
  ]
  ++ extraModules;

  # FIXME: Refactor me! (Use submodules?)
  mkFlake = {
    self
    , hey ? self
    , nixpkgs ? hey.inputs.nixpkgs
    , ...
  } @ inputs: {
    apps ? {}
    , checks ? {}
    , devShells ? {}
    , hosts ? {}
    , modules ? {}
    , overlays ? {}
    , packages ? {}
    , systems
    , templates ? {}
    , ...
  } @ flake:
    let
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = attrValues overlays;
        config.allowUnfree = true;
        # A number of packages depend on python 2.7, but nixpkgs errors out when
        # it is pulled, so...
        config.permittedInsecurePackages = [ "python-2.7.18.6" ];
      };

      # One package set per system, not one per host. Instantiating nixpkgs is
      # expensive and every host on a system wants the identical set. The
      # fallback covers a host whose system isn't in 'systems'.
      pkgsBySystem = genAttrs systems mkPkgs;
      pkgsFor = system: pkgsBySystem.${system} or (mkPkgs system);

      # hey.lib's package helpers (mkWrapper, mkLauncherEntry) want nixpkgs and
      # the flake-level lib has none it can use purely. Each host gets a lib
      # over its own, the same way test/nixos/_lib.nix does.
      libFor = system: import ./. { inherit lib; pkgs = pkgsFor system; };

      # `self.{dir,*Dir}` is the store snapshot nix is evaluating; read files
      # through it (readFile, pathExists, import). `config.hey.{dir,*Dir}` is
      # the live checkout, outside the store, for paths that end up in the built
      # system (links, PATH, sourced rc files) so an edit there doesn't wait for
      # a rebuild.
      nixosConfigurations = mapAttrs (hostName: { path, config }:
        # TODO: Replace with a submodule
        let
          heyLib = libFor host.system;
          self' = mkHey {
            inherit (host) system;
            inherit heyLib;
            flake = self;
            hostDir = path;
          } // dirsOf (toString self);
          hey' = mkHey {
            inherit heyLib;
            inherit (host) system;
            flake = hey;
            hostDir = path;
          };
          host = config {
            inherit lib;
            nixosModules = hey'.modules;
            hey = hey';
          };
        in
          nixpkgs.lib.nixosSystem {
            system = host.system;
            specialArgs.self = self';
            specialArgs.hey = hey';
            modules = mkHostModules {
              inherit host hostName;
              pkgs = pkgsFor host.system;
            };
          }) hosts;

      # callPackage first: the platform filter reads meta off the built
      # derivation, not off the package function.
      withPkgs = system: extraArgs: packageAttrs:
        let pkgs = pkgsFor system; in
        filterAttrs
          (_: v: !(v ? meta.platforms) || (elem system v.meta.platforms))
          (mapAttrs
            (_: v: pkgs.callPackage v
                     ({ self = self.packages.${system}; } // extraArgs))
            packageAttrs);

      # Drops any system that came out empty, so 'nix flake show' stays free of
      # dead keys. The outer filter drops an output empty for every system.
      bySystem = fn: filterAttrs (_: v: v != {}) (genAttrs systems fn);

      perSystem = filterAttrs (_: v: v != {}) {
        apps = bySystem (_: apps);
        # test/nixos needs this flake's own inputs and 'self' is already taken
        # by the package set.
        checks = bySystem (system: withPkgs system { flake = self; } checks);
        devShells = bySystem (system: withPkgs system {} devShells);
        packages = bySystem (system: withPkgs system {} packages);
      };
    in
      (removeAttrs flake [
        "apps" "checks" "devShells" "hosts" "modules" "packages" "systems"
      ]) // {
          inherit nixosConfigurations;
          nixosModules = modules;
      } // perSystem;
}
