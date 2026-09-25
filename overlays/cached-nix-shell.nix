# overlays/cached-nix-shell.nix
#
# Nix 2.34 nested `nix derivation show`'s output under "derivations" and made
# the .drv names store-relative. cached-nix-shell 0.1.6 takes the first key as
# the .drv's path, caches a symlink to the word "derivations", then fails its own
# "does the .drv still exist" check on every run. So it never hits the cache and
# everything with it in a shebang eats a ~2s nix-shell eval. Upstream hasn't
# moved since 2024, hence this. If it ever stops applying, check whether
# upstream finally fixed it before fixing the patch.

final: prev: {
  cached-nix-shell = prev.cached-nix-shell.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      (final.writeText "cached-nix-shell-nix-2.34.patch" ''
        --- a/src/main.rs
        +++ b/src/main.rs
        @@ -317,9 +317,16 @@
                 let output = String::from_utf8_lossy(&exec.stdout);
                 let output: serde_json::Value =
                     serde_json::from_str(&output).expect("failed to parse json");
        +        // Nix 2.34+ nests it under "derivations", relative to the store.
        +        let output = output.get("derivations").unwrap_or(&output);
                 // The first key of the toplevel object contains the path to .drv file.
                 let (drv, _) = output.as_object().unwrap().into_iter().next().unwrap();
        -        drv.clone()
        +        if drv.starts_with('/') {
        +            drv.clone()
        +        } else {
        +            let store = std::path::Path::new(env_out).parent().unwrap();
        +            store.join(drv).to_string_lossy().into_owned()
        +        }
             };
         
             NixShellOutput { env, trace, drv }
      '')
    ];
  });
}
