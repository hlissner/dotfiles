# test/nixos/_lib.nix --- the guts of the nixos test suite
#
# NOTE: The '_' prefix keeps this file out of collectSuites' sweep.
#
# Every suite under test/nixos/ is a function taking this attrset and returning
# an attrset in nixpkgs' lib.runTests shape:
#
#   { evalConfig, ... }: {
#     testHyprlandEnablesQt = {
#       expr = (evalConfig [{ modules.wm.desktop = "hyprland"; }]).qt.enable;
#       expected = true;
#     };
#   }
#
# This harness fabricates the 'hey' argument itself (with the real mkHey, so
# it can't drift) instead of building flake.nixosConfigurations, so a suite
# can point a module at a fixture tree rather than at /etc/dotfiles.

{ lib, pkgs, flake }:

with builtins;
with lib;
let
  dir = toString ../..;
  system = pkgs.stdenv.hostPlatform.system;
in rec {
  inherit lib pkgs flake dir system;

  # Built here rather than taken from flake.lib on purpose: that one has no
  # package set, so mkWrapper and friends throw off it. Handing this one the
  # check's own pkgs gives the library under test the same package set the
  # modules get, just as mkFlake does per host.
  heyLib = import ../../lib { self = flake; inherit lib pkgs; };

  # Every host in hosts/, unevaluated: { <name> = { path, config }; }
  hosts = heyLib.mapHosts ../../hosts;

  # A stand-in for the 'hey' specialArg mkFlake assembles, and for 'self' too.
  #
  # DIR stands in for the store snapshot. Point it at a fixture tree to feed a
  # module config/ files the live ones would otherwise decide for it. What a
  # module *links* to is hey.dir, an option, and stays /etc/dotfiles here as on
  # any host; a suite that wants links to follow the fixture sets it (and gets
  # the store-path assertion it deserves, should it force one).
  mkHey =
    { dir ? toString ../..
    , hostDir ? dir
    }:
    heyLib.mkHey {
      inherit flake system hostDir heyLib;
    } // heyLib.dirsOf dir;

  # Evaluates a resolved host attrset. The primed variant keeps the whole
  # nixosSystem, for the tests that read an option's declaration (its type,
  # say) instead of hardcoding what it allows.
  evalSystem' =
    { host
    , hostName ? "test"
    , hey ? mkHey {}
    , extraModules ? []
    }:
    flake.inputs.nixpkgs.lib.nixosSystem {
      system = host.system;
      specialArgs = {
        self = hey;
        # Minus the dirs, so a module reaching for hey.configDir fails here the
        # way it would on a host.
        hey = removeAttrs hey (attrNames (heyLib.dirsOf ""));
      };
      modules = heyLib.mkHostModules {
        inherit host hostName pkgs extraModules;
      };
    };

  evalSystem = args: (evalSystem' args).config;

  # Applies a host out of `hosts` above without evaluating it into a NixOS
  # system. Use it to assert on what a host declares, as opposed to what its
  # evaluated configuration comes out as.
  applyHost = hostName: { path, config }:
    let hey = mkHey { hostDir = toString path; };
    in {
      inherit hey;
      host = config {
        inherit lib hey;
        nixosModules = hey.modules;
      };
    };

  # Applies and evaluates one host out of `hosts` above.
  #
  # Takes extra modules for the cases where a host cannot be evaluated purely as
  # written (see presets.hosts below).
  evalHost' = extraModules: hostName: hostAttrs:
    let applied = applyHost hostName hostAttrs;
    in evalSystem {
      inherit hostName extraModules;
      inherit (applied) hey host;
    };

  evalHost = evalHost' [];

  # The floor every module eval needs: a user, a root filesystem, and enough
  # system to keep the module system quiet. Intentionally thin, so a test's own
  # modules are the only interesting input.
  baseModules = [{
    modules.profiles.user = "test";
    user.name = "test";
    system.stateVersion = "23.11";
    boot.loader.grub.enable = false;
    # default.nix defaults the root device but not its fsType, and profile
    # modules do read fileSystems (hardware/ssd.nix branches on whether any
    # filesystem is zfs), so a real host's hardware block has to be stood in for
    # here.
    fileSystems."/" = { device = "/dev/null"; fsType = "ext4"; };
    # Building manpages for every eval would dominate the runtime.
    documentation.enable = false;
    documentation.nixos.enable = false;
  }];

  # Evaluates the root module tree (../../default.nix) against MODULES and
  # returns the resulting `config`. The workhorse of the modules/ suites.
  # evalModules' returns the whole nixosSystem instead, options and all.
  evalModules' = hey: modules:
    evalSystem' {
      inherit hey;
      host = {
        inherit system;
        config = { ... }: { imports = baseModules ++ modules; };
      };
    };

  evalConfig' = hey: modules: (evalModules' hey modules).config;

  evalConfig = evalConfig' (mkHey {});

  # The evaluations more than one suite reads. Every suite is joined into one
  # derivation, so one nix process evaluates them all and these are paid for
  # once rather than once per suite. They are the whole reason for sharing:
  # a full system eval is most of any suite's runtime.
  presets = {
    # The bare system whole, for the options a suite reads declarations off.
    nixos = evalModules' (mkHey {}) [];
    bare = presets.nixos.config;
    hyprland = evalConfig [{ modules.wm.desktop = "hyprland"; }];

    # Every host in hosts/, evaluated.
    hosts = mapAttrs evalHost hosts;
  };

  # Walks DIR for suites: every *.nix file, recursively, minus '_'-prefixed
  # names, '*.d' fixture directories, and default.nix.
  #
  # NOTE: Can't use mapModulesRec here; it recurses into every directory it
  # finds, so it would import lib/modules.d's fixtures as if they were test
  # suites.
  #
  # collectSuites :: path -> { <suite-name> = path; }
  collectSuites = root:
    let
      walk = prefix: dir:
        concatLists (mapAttrsToList (n: type:
          let name = if prefix == "" then n else "${prefix}-${n}";
              path = "${toString dir}/${n}";
          in
            if hasPrefix "_" n then []
            else if type == "directory" then
              (if hasSuffix ".d" n then [] else walk name path)
            else if type == "regular"
                    && hasSuffix ".nix" n
                    && n != "default.nix"
            then [ (nameValuePair (removeSuffix ".nix" name) path) ]
            else []
        ) (readDir dir));
    in listToAttrs (walk "" root);

  # Runs one suite and returns a derivation that builds quietly on success.
  #
  # The stray-name guard is intentional: lib.runTests silently ignores any
  # attribute not named test*; a typo'd name is a test that silently never runs.
  mkSuite = name: tests:
    let
      strays = filter (n: !(hasPrefix "test" n)) (attrNames tests);
      failures = runTests tests;
      total = length (attrNames tests);
    in
      pkgs.runCommand "nixos-test-${name}"
        {
          passthru = { inherit tests failures strays; };
          passAsFile = [ "report" ];
          report =
            (optionalString (strays != []) ''
              ${toString (length strays)} test(s) are not named test*, so
              lib.runTests will never run them:

              ${concatMapStringsSep "\n" (n: "  ${n}") strays}

            '')
            + (optionalString (failures != [])
                (generators.toPretty { multiline = true; } failures));
        }
        (if strays == [] && failures == [] then ''
          mkdir -p "$out"
          echo "ok  ${name}  (${toString total} tests)" | tee "$out/${name}"
        '' else ''
          echo "FAIL  ${name}  (${toString (length failures)} of ${toString total} failed${optionalString (strays != []) ", ${toString (length strays)} misnamed"})" >&2
          echo >&2
          cat "$reportPath" >&2
          exit 1
        '');
}
