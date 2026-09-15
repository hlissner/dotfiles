# packages/_janet.nix -- the machinery behind hey and heyops
#
# Both binaries are the same derivation with a different entry point, so the
# builder lives here rather than twice over. The '_' prefix keeps this file out
# of mapModules' sweep (see lib/modules.nix); it is not a package.

{ lib, stdenv, runCommand, fetchFromGitHub, janet, jpm, gcc }:

with lib;
let
  # The janet libraries hey and everything it dispatches to need. Order matters:
  # janet-sh declares posix-spawn as a dependency. sqlite3 isn't linked into hey
  # at all -- it's here for config/rofi/bin/bookmarkmenu.janet, which stays
  # interpreted. Keep this in sync with project.janet's :dependencies.
  janetDeps = [
    (fetchFromGitHub {
      owner = "andrewchambers"; repo = "janet-posix-spawn";
      rev = "3e68f493a6c3b8ed5c333750e33a11ea1a3d00f7";
      hash = "sha256-+Xr7Z0ETQi/ofLRBcTcGv6KtTk04V7/Chfg/IZNB7zY=";
    })
    (fetchFromGitHub {
      owner = "andrewchambers"; repo = "janet-sh";
      rev = "221bcc869bf998186d3c56a388c8313060bfd730";
      hash = "sha256-pqpEs/qfHe/e2ywSuqzWZhfw/YHZNkTsKHZHoaoVTc4=";
    })
    (fetchFromGitHub {
      owner = "janet-lang"; repo = "spork";
      rev = "0667f96b74de52747ffe5e19e185563ebf53816b";
      hash = "sha256-F/wU9XBvsL56JySUzcYdC/w+ETn9c2L3AdEgs5tInyY=";
    })
    (fetchFromGitHub {
      owner = "janet-lang"; repo = "sqlite3";
      rev = "c7a6f36affd217182bd9b0228c58d33d04361689";
      hash = "sha256-UGIDTLdGEbOR2RjfQliH0X7SRKi271ZzrSPzrP1M7mc=";
    })
  ];

  # Split out so the dependencies build once instead of once per binary (72s ->
  # 7s incremental). Don't inline it back.
  janetTree = stdenv.mkDerivation {
    pname = "hey-janet-tree";
    version = "0";

    dontUnpack = true;
    dontConfigure = true;
    nativeBuildInputs = [ janet jpm gcc ];

    buildPhase = ''
      runHook preBuild

      export JANET_TREE="$NIX_BUILD_TOP/tree"
      export JANET_PATH="$JANET_TREE/lib"
      export JANET_BINPATH="$JANET_TREE/bin"
      export JANET_BUILDPATH="$NIX_BUILD_TOP/build"
      mkdir -p "$JANET_PATH" "$JANET_BINPATH" "$JANET_BUILDPATH"

      for dep in ${escapeShellArgs janetDeps}; do
        # jpm builds in-tree, and a store path is read-only.
        cp -r --no-preserve=mode,ownership "$dep" dep
        (cd dep && jpm install --offline --tree="$JANET_TREE")
        rm -rf dep
      done

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r "$JANET_TREE" $out
      runHook postInstall
    '';

    meta.description = "The janet libraries hey builds against";
  };
in rec {
  inherit janetTree;

  # Everything an interpreted `(use hey)` needs: the pinned deps, plus lib/hey
  # itself. quickbin bakes this into the binary, but the scripts hey dispatches
  # to and doesn't compile -- config/rofi/bin/*.janet, bin/lab.d/* -- have to
  # find it on JANET_PATH.
  janetLibs = runCommand "hey-janet-libs" {
    meta.description = "hey's janet libraries, for the scripts it doesn't compile in";
  } ''
    cp -r ${janetTree}/lib $out
    chmod -R u+w $out
    cp -r ${../lib/hey} $out/hey
  '';

  mkJanetBin = { name, description, passthru ? {} }:
    stdenv.mkDerivation {
      pname = name;
      version = "0";

      src = fileset.toSource {
        root = ../.;
        # Only what quickbin compiles in: the entry point and its .d/. Anything
        # wider and an unrelated bin/ script rebuilds the CLI. project.janet
        # isn't here because `jpm quickbin` never reads it.
        fileset = fileset.unions [ (../bin + "/${name}") (../bin + "/${name}.d") ];
      };

      dontConfigure = true;
      nativeBuildInputs = [ janet jpm gcc ];

      buildPhase = ''
        runHook preBuild

        # A copy, not the store path itself: jpm writes into the tree it builds
        # against, and a store path is read-only.
        export JANET_PATH="$NIX_BUILD_TOP/lib"
        export JANET_TREE="$NIX_BUILD_TOP"
        export JANET_BUILDPATH="$NIX_BUILD_TOP/build"
        cp -r --no-preserve=mode,ownership ${janetLibs} "$JANET_PATH"
        mkdir -p "$JANET_BUILDPATH"

        jpm quickbin bin/${name} ${name}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        install -Dm755 ${name} $out/bin/${name}
        runHook postInstall
      '';

      inherit passthru;
      meta = { inherit description; mainProgram = name; };
    };
}
