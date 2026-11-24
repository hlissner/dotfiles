# packages/rom-patcher.nix --- apply ips, bps, ups, ppf, aps, rup, bdf patches
#
# RomPatcher.js is what RomM uses to apply patches.

{ lib, stdenvNoCC, fetchFromGitHub, nodejs, ... }:

stdenvNoCC.mkDerivation {
  pname = "rom-patcher";
  version = "3.0.0-unstable-2026-10-21";

  src = fetchFromGitHub {
    owner = "marcrobledo";
    repo = "RomPatcher.js";
    rev = "4f17297cd1dc0835a0b0747497fa15f5f63f1623";
    hash = "sha256-qIkAeiNSeudMW7gaG1kU1iDrFYGVBGL456xO5AqChOU=";
  };

  buildInputs = [ nodejs ];
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib $out/bin
    cp -r rom-patcher-js $out/lib/
    cat > $out/bin/rom-patcher <<EOF
    #!/usr/bin/env node
    const RomPatcher = require('$out/lib/rom-patcher-js/RomPatcher');
    const [rom, patch, out] = process.argv.slice(2);
    if (!out) {
      console.error('Usage: rom-patcher ROM PATCH OUT');
      process.exit(2);
    }
    try {
      const parsed = RomPatcher.parsePatchFile(new BinFile(patch));
      if (!parsed) throw new Error('Not a patch format I know');
      const patched = RomPatcher.applyPatch(new BinFile(rom), parsed, { requireValidation: true });
      const u8 = patched._u8array;
      require('fs').writeFileSync(out, Buffer.from(u8.buffer, u8.byteOffset, u8.byteLength));
    } catch (e) {
      console.error(patch + ': ' + e.message);
      process.exit(1);
    }
    EOF
    chmod +x $out/bin/rom-patcher
  '';

  meta = {
    description = "RomPatcher.js, with a CLI that fails when the patch does";
    homepage = "https://github.com/marcrobledo/RomPatcher.js";
    license = lib.licenses.mit;
    mainProgram = "rom-patcher";
  };
}
