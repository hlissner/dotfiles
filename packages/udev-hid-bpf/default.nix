# packages/udev-hid-bpf

{ lib, stdenv, fetchFromGitLab, rustPlatform, cargo, rustc, meson, ninja,
  pkg-config, python3, llvmPackages, bpftools, libbpf, elfutils, zlib, udev, ... }:

let
  quirks = lib.filter (lib.hasSuffix ".bpf.c") (lib.attrNames (builtins.readDir ./.));
in
stdenv.mkDerivation (final: {
  pname = "udev-hid-bpf";
  version = "2.3.0-20260703";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "libevdev";
    repo = "udev-hid-bpf";
    tag = final.version;
    hash = "sha256-MfAiOCOE2UeS0MGyWgwJ2GW3qO2fo6TPrB9W1MT0NWQ=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (final) pname version src;
    hash = "sha256-Jje8326ESCBI/vnyv6HIKu7R2hfG7uE0d/orx15yQ/Q=";
  };

  postPatch = ''
    patchShebangs tools/
    ${lib.concatMapStringsSep "\n" (f: ''
      cp ${./. + "/${f}"} src/bpf/testing/${f}
      sed -i "s/^sources = \\[/&\\n    '${f}',/" src/bpf/testing/meson.build
    '') quirks}
  '';

  nativeBuildInputs = [
    meson ninja pkg-config python3 cargo rustc rustPlatform.cargoSetupHook
    llvmPackages.clang bpftools
  ];
  buildInputs = [ libbpf elfutils zlib udev ];

  # Same three nixpkgs' systemd turns off: the wrapped clang injects them and
  # `-target bpf` chokes.
  hardeningDisable = [ "zerocallusedregs" "shadowstack" "pacret" ];

  mesonFlags = [
    "-Dbpfs=stable,testing"
    "-Dudevdir=${placeholder "out"}/lib/udev"
    "-Dbpfdirs=PREFIXED_BPFDIR"
    "-Dtests=disabled"
  ];

  # Wants a pty and the real udev.
  doCheck = false;

  # Keep nix's fixup away from the BPF objects: they're ELF, but not ours to
  # strip or patchelf.
  dontPatchELF = true;
  stripDebugList = [ "bin" ];

  meta = {
    description = "Automatic HID-BPF loader based on udev events";
    homepage = "https://gitlab.freedesktop.org/libevdev/udev-hid-bpf";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "udev-hid-bpf";
  };
})
