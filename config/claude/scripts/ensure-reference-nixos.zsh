#!/usr/bin/env zsh
# Index NixOS's options into data/refs/nixos: upstream's, from the installed
# nixpkgs, and this repo's own modules.*, from the working tree.

source ${0:A:h}/lib/reference.zsh

nixpkgs=$(nixpath nixpkgs) || die "no nixpkgs in NIX_PATH"
# The modules half moves every time I touch a module, the upstream half only
# when nixpkgs does; keyed apart so the one doesn't rebuild the other.
upstream="$(<$nixpkgs/.version) ${nixpkgs:t}"
tree=$(cat $REF_REPO/{flake.lock,default.nix,{modules,lib}/**/*.nix}(.N) | cksum) || die "can't read $REF_REPO"
tree=${tree%% *}

build() {
  local expr=$REF_LIB/nixos-options.nix
  if [[ -r $REF_DIR/.upstream && "$(<$REF_DIR/.upstream)" == "$upstream" ]]; then
    cp $REF_DIR/{.upstream,options.json,options.index} .
  else
    local json=$(nix build --no-link --print-out-paths --impure \
                   --file $expr --argstr nixpkgs $nixpkgs upstream)
    cp $json/share/doc/nixos/options.json .
    chmod u+w options.json
    need python3
    python3 $REF_LIB/nixos-options.py options.json options.index
    print -r -- $upstream > .upstream
  fi

  # A module I've broken mid-edit shouldn't cost upstream's index too
  nix eval --impure --raw --file $expr --argstr repo $REF_REPO local \
    > options-local.index \
    || rm -f options-local.index

  cat > README.md <<EOF
# NixOS options (${upstream%% *})

- \`options.index\` -- upstream's options, one line each, as
  \`name :: type :: default :: first sentence\`. Grep this first.
- \`options.json\` -- the full upstream records. Don't read it whole;
  pull one out by name:

      jq '."services.nginx.enable"' options.json

- \`options-local.index\` -- the \`modules.*\` options *this repo's working
  tree* declares, which no published manual covers. Three fields, not four:
  \`name :: type :: description\`. Defaults are deliberately absent (rendering
  them is an eval cycle) -- read the module under \`modules/\` for those.
  Missing if the tree didn't evaluate when this was last built.
EOF
}

ensure "$upstream modules@$tree"
