# nix build --impure --file nixos-options.nix --argstr nixpkgs PATH upstream
# nix eval --impure --raw --file nixos-options.nix --argstr repo PATH local
{ nixpkgs ? <nixpkgs>, repo ? null }:

let lib = import "${nixpkgs}/lib";
    system = builtins.currentSystem;
in {
  # The same options.json the NixOS manual is rendered from, so identical to
  # what the installed system's manual would list -- and on cache.nixos.org,
  # because it doesn't depend on anything of mine.
  upstream = (import "${nixpkgs}/nixos/lib/eval-config.nix" {
    inherit system;
    modules = [{ system.stateVersion = lib.trivial.release; }];
  }).config.system.build.manual.optionsJSON;

  # This repo's own modules.*, through the test harness, since that needs
  # neither $HEYENV nor a host. Not a git+file: flake, because git can't open
  # the dotfiles the sandbox masks, and not path: on the repo directly, which
  # would drag data/ into the store with it.
  local =
    let skip = map (p: "${repo}/${p}") [
          ".git" "result" "config/claude/data"
        ];
        src = builtins.path {
          name = "dotfiles";
          path = repo;
          # "unknown" is the sandbox's /dev/null stand-ins for masked files
          filter = p: t:
            t != "unknown" && baseNameOf p != "secrets" && !(builtins.elem p skip);
        };
        flake = builtins.getFlake "path:${builtins.unsafeDiscardStringContext src}";
        pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
        harness = import "${src}/test/nixos/_lib.nix" {
          inherit flake pkgs;
          inherit (pkgs) lib;
        };
        # evalConfig hands back config, not options; smuggle them out.
        config = harness.evalConfig [({ options, ... }: {
          options.claudeOptions = lib.mkOption {
            type = lib.types.raw;
            default = options.modules;
          };
        })];
        oneLine = s:
          let text = if builtins.isAttrs s then s.text or "" else toString s;
          in builtins.substring 0 240
            (builtins.replaceStrings [ "\n" "\r" "\t" ] [ " " " " " " ] text);
        keep = o: !(o.internal or false) && (o.visible or true);
        line = o: "${o.name} :: ${o.type} :: ${oneLine (o.description or "")}";
    in lib.concatMapStrings (o: line o + "\n")
      (builtins.filter keep (lib.optionAttrSetToDocList config.claudeOptions));
}
