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

  mkHey = {
    flake
  , system
  , dir
  , hostDir ? dir
  , args ? {}
  }:
    let dir' = if dir != "" then dir
               else throw "mkHey: dir is empty";
    in forSystem system flake // {
      inherit args hostDir;
      inputs = mapAttrs (_: forSystem system) flake.inputs;
      modules = nixosModulesOf flake.inputs;
      dir         = dir';
      binDir      = "${dir'}/bin";
      libDir      = "${dir'}/lib";
      configDir   = "${dir'}/config";
      modulesDir  = "${dir'}/modules";
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
      # Processes external arguments that bin/hey will feed to this flake (using
      # a json payload in an envvar). The internal var is kept in lib to stop
      # 'nix flake check' from complaining more than it has to.
      #
      # This is the only impurity we allow into this flake, because there are
      # many times where it is convenient to generate or seed dotfiles or
      # envvars with local (non-nix-store) paths instead, so I don't have to
      # rebuild each time I change/swap them out.
      args =
        let hargs = getEnv "HEYENV"; in
        if hargs == ""
        then throw "HEYENV envvar is missing"
        else fromJSON hargs;

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

      nixosConfigurations = mapAttrs (hostName: { path, config }:
        # TODO: Replace with a submodule
        let
          self' = mkHey {
            inherit args;
            inherit (host) system;
            flake = self;
            dir = toString self;
            hostDir = path;
          };
          hey' = mkHey {
            inherit args;
            inherit (host) system;
            flake = hey;
            dir = args.path;
            hostDir = path;
          };
          host = config {
            inherit args lib;
            nixosModules = hey'.modules;
            hey = hey';
          };
        in
          nixpkgs.lib.nixosSystem {
            system = host.system;
            specialArgs.self = self';
            specialArgs.hey = hey';
            modules = mkHostModules {
              inherit host;
              pkgs = pkgsFor host.system;
              hostName = args.host or hostName;
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
      } // perSystem;
}
