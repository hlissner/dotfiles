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
# Nothing here needs $HEYENV or --impure. mkFlake reads HEYENV and aborts
# without it, so this harness fabricates the 'hey' argument itself (with the
# real mkHey, so it can't drift) instead of building flake.nixosConfigurations.

{ lib, pkgs, flake }:

with builtins;
with lib;
let
  dir = toString ../..;
  system = pkgs.stdenv.hostPlatform.system;
in rec {
  inherit lib pkgs flake dir system;

  # Built here rather than taken from flake.lib on purpose. flake.nix seeds the
  # library with `import nixpkgs {}`, which falls back to builtins.currentSystem
  # and would drag --impure into every suite the moment a module touched a
  # pkgs-dependent helper like mkWrapper. Handing it the check's own pkgs keeps
  # the suites pure, and gives the library under test the same package set the
  # modules get.
  heyLib = import ../../lib { self = flake; inherit lib pkgs; };

  # Every host in hosts/, unevaluated: { <name> = { path, config }; }
  hosts = heyLib.mapHosts ../../hosts;

  # A pure stand-in for the 'hey' specialArg that mkFlake assembles from
  # $HEYENV.
  mkHey =
    { hostDir ? dir
    , host ? "test"
    , user ? "test"
    }:
    heyLib.mkHey {
      inherit flake system dir hostDir;
      args = { inherit host user; path = dir; };
    } // {
      # mkHey derives this from the flake, and flake.lib is the impure copy;
      # every module reads its helpers off hey.lib, so point it at ours.
      lib = heyLib;
    };

  # Evaluates a resolved host attrset
  evalSystem =
    { host
    , hostName ? "test"
    , hey ? mkHey {}
    , extraModules ? []
    }:
    (flake.inputs.nixpkgs.lib.nixosSystem {
      system = host.system;
      specialArgs = { inherit hey; self = hey; };
      modules = heyLib.mkHostModules {
        inherit host hostName pkgs extraModules;
      };
    }).config;

  # Applies a host out of `hosts` above without evaluating it into a NixOS
  # system. Use it to assert on what a host declares, as opposed to what its
  # evaluated configuration comes out as.
  applyHost = hostName: { path, config }:
    let hey = mkHey { hostDir = toString path; host = hostName; };
    in {
      inherit hey;
      host = config {
        inherit lib hey;
        args = hey.args;
        nixosModules = hey.modules;
      };
    };

  # Applies and evaluates one host out of `hosts` above.
  #
  # Takes extra modules for the cases where a host cannot be evaluated purely as
  # written (see test/nixos/hosts.nix).
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
  evalConfig = modules:
    evalSystem {
      host = {
        inherit system;
        config = { ... }: { imports = baseModules ++ modules; };
      };
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
