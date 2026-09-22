# modules/shell/claude.nix
#
# Oh AI, destroyer of the internet, open source, and all that is creative. Owned
# by the most morally bankrupt humans on Earth, a deleterious economic/politic
# force that does more bad than good, and when its bubble pops 2008 and 2001
# will look like vacations. Give me back affordable ram.

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.shell.claude;
    system = pkgs.stdenv.hostPlatform.system;
    settingsFormat = pkgs.formats.json {};

    # I ask claude about my stack (Hyprland, Noctalia, Nix, NixOS, and Janet)
    # often and it burns way too many tokens just sifting through HTML docs
    # online en mass. So I download and massage them locally (pinned to the
    # versions I have installed) and create small indecies for Claude to dig
    # through incrementally.

    html2md = pkgs.writeText "html2md.py" ''
      import re, subprocess, sys

      # For Hugo and mdBook
      SELECTORS = ('<div class="content">', '<main id="content"', '<main')

      def extract(html):
          for sel in SELECTORS:
              i = html.find(sel)
              if i >= 0:
                  end = "</main>" if sel.startswith("<main") else "</div>"
                  j = html.rfind(end)
                  if j > i:
                      return html[i:j]
          return None

      def main(src, dst):
          html = open(src, encoding="utf-8", errors="replace").read()
          # Hextra answers a bad URL with an 404 page but HTTP 200
          if "hextra-error" in html:
              print("soft 404: %s" % src, file=sys.stderr)
              return 3
          body = extract(html)
          if body is None:
              print("no content element: %s" % src, file=sys.stderr)
              return 4
          body = re.sub(r"<(script|style|svg)\b.*?</\1>", "", body, flags=re.S)
          body = re.sub(r'<img[^>]*src="data:[^"]*"[^>]*>', "", body)
          body = re.sub(r"<button\b.*?</button>", "", body, flags=re.S)
          md = subprocess.run(
              ["pandoc", "-f", "html", "-t", "gfm-raw_html", "--wrap=none"],
              input=body, capture_output=True, text=True, check=True).stdout
          # Hugo hangs an empty self-links and pandoc faithfully renders it as
          # `[](#the-heading)`
          md = re.sub(r"\s*\[\]\(#[^)]*\)", "", md)
          md = re.sub(r"\n{3,}", "\n\n", md).strip() + "\n"
          if len(md) < 32:
              print("empty after conversion: %s" % src, file=sys.stderr)
              return 5
          open(dst, "w", encoding="utf-8").write(md)
          return 0

      sys.exit(main(sys.argv[1], sys.argv[2]))
    '';

    # Convert noisy HTML into markdown
    mirrorHtml = { name, version, src, root ? "." }:
      pkgs.runCommand "${name}-${version}" {
        nativeBuildInputs = with pkgs; [ python3 pandoc ];
        passthru = { inherit version; };
      } ''
        mkdir -p "$out"
        cd ${src}/${root}
        find . -name '*.html' | sort | while IFS= read -r f; do
          dst="$out/''${f#./}"
          dst="''${dst%.html}.md"
          mkdir -p "$(dirname "$dst")"
          python3 ${html2md} "$f" "$dst" || rm -f "$dst"
        done
        if [ -z "$(find "$out" -name '*.md' -print -quit)" ]; then
          echo "${name}: converted zero pages -- upstream markup moved?" >&2
          exit 1
        fi
      '';

    # code.claude.com is a rolling release, so I keep it outside of the store.
    # Kept up-to-date by `claude-code-docs.service` below.
    claudeCodeCache = "/var/cache/claude-code-docs";
    claudeCodeDir = "${claudeCodeCache}/docs";
    liveClaudeCodeDocs =
      (cfg.resources.sources.claude-code or null) == claudeCodeDir;

    hyprlandPackage = hey.inputs.hyprland.packages.${system}.hyprland;
    # "0.56.0+date=2026-09-19_83cf6a6" -> "0.56.0", same way the wiki versions
    hyprlandVersion = head (splitString "+" hyprlandPackage.version);
    hyprlandWiki =
      let site = pkgs.stdenvNoCC.mkDerivation {
            pname = "hyprland-wiki-site";
            version = hyprlandVersion;

            nativeBuildInputs = with pkgs; [ cacert curl ];
            dontUnpack = true;

            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = cfg.resources.hashes.hyprland;

            buildPhase = ''
              base="https://wiki.hypr.land/${hyprlandVersion}"
              curl -fsSL "$base/sitemap.xml" -o sitemap.xml
              grep -oE '<loc>[^<]+</loc>' sitemap.xml \
                | sed -E 's:</?loc>::g' \
                | grep "^$base/" | sort -u > urls
              test -s urls || {
                echo "wiki.hypr.land has no ${hyprlandVersion} build; check its version selector" >&2
                exit 1
              }
              xargs -P8 -I{} sh -c '
                rel=''${1#"$2"/}
                rel=''${rel%/}
                mkdir -p "html/$rel"
                curl -fsSL --retry 3 "$1" -o "html/$rel/index.html"
              ' _ {} "$base" < urls
            '';

            installPhase = ''cp -r html "$out"'';
          };
      in mirrorHtml {
        name = "hyprland-wiki";
        version = hyprlandVersion;
        src = site;
      };

    janetDocs =
      let site = pkgs.fetchFromGitHub {
            owner = "janet-lang"; repo = "janet-lang.org";
            rev = "cef8ddbf66d9236686352bc4fa0913e9e8eca11c";
            hash = "sha256-W0n66+vgwENOUXWrlU1vFHUp6RbreJAqAd/zolHbmeE=";
          };
      in pkgs.runCommand "janet-docs-${pkgs.janet.version}" {
        nativeBuildInputs = [ pkgs.janet ];
        passthru = { inherit (pkgs.janet) version; };
      } ''
        mkdir -p "$out"/manual
        # .mdz is just markdown with @code`...` for spans
        cp -r ${site}/content/docs/. "$out"/manual/
        cp -r ${site}/content/api "$out"/api-prose

        # root-env iterates in hash order; sort or the output isn't
        # reproducible and the derivation churns on every rebuild.
        janet -e '
          (def entries @[])
          (eachp [k v] root-env
            (when (and (symbol? k) (get v :doc))
              (array/push entries [(string k) (get v :doc)])))
          (sort-by first entries)
          (print "# Janet " janet/version " core API")
          (print)
          (print "Dumped from the installed interpreter; exact by construction.")
          (print)
          (each [name doc] entries
            (print "## " name)
            (print)
            (print doc)
            (print))
        ' > "$out"/core-api.md

        test -s "$out"/core-api.md || {
          echo "janet dumped no docstrings" >&2; exit 1
        }
      '';

    # Already in the store. Yay!
    nixManual = mirrorHtml {
      name = "nix-manual";
      version = pkgs.nix.version;
      src = pkgs.nix.doc;
      root = "share/doc/nix/manual";
    };

    # Build a JSON index of NixOS options for quick lookups
    nixosOptionsIndex = pkgs.writeText "nixos-options-index.py" ''
      import json, re, sys

      opts = json.load(open(sys.argv[1]))

      def flat(v):
          # Defaults and examples arrive as {_type, text} literals as often
          # as plain values; both want to end up on one line.
          if isinstance(v, dict):
              v = v.get("text", v.get("value", ""))
          return re.sub(r"\s+", " ", str(v)).strip()

      def first_sentence(desc):
          d = re.sub(r"\s+", " ", desc or "").strip()
          m = re.match(r"(.+?[.!?])(\s|$)", d)
          return (m.group(1) if m else d)[:240]

      with open(sys.argv[2], "w") as fd:
          for name in sorted(opts):
              o = opts[name]
              fd.write("%s :: %s :: %s :: %s\n" % (
                  name,
                  flat(o.get("type", ""))[:80] or "?",
                  flat(o.get("default", ""))[:80] or "-",
                  first_sentence(o.get("description", ""))))
    '';

    # Include options in my own dotfiles.
    localOptionsIndex =
      let
        oneLine = s:
          let text = if isAttrs s then s.text or "" else toString s;
              flat = replaceStrings [ "\n" "\r" "\t" ] [ " " " " " " ] text;
          in substring 0 240 flat;
        keep = o:
          hasPrefix "modules." o.name
          && !(o.internal or false)
          && (o.visible or true);
        line = o: "${o.name} :: ${o.type} :: ${oneLine (o.description or "")}";
        docs = filter keep (optionAttrSetToDocList options);
      in pkgs.writeText "options-local.index"
        (concatMapStringsSep "\n" line docs + "\n");

    nixosOptions =
      let version = config.system.nixos.release;
      in pkgs.runCommand "nixos-options-${version}" {
        nativeBuildInputs = [ pkgs.python3 ];
        passthru = { inherit version; };
        json = "${config.system.build.manual.optionsJSON}/share/doc/nixos/options.json";
      } ''
        mkdir -p "$out"
        cp "$json" "$out"/options.json
        python3 ${nixosOptionsIndex} "$json" "$out"/options.index
        cp ${localOptionsIndex} "$out"/options-local.index

        cat > "$out"/README.md <<'EOF'
        # NixOS options (${version})

        - `options.index` -- upstream's ~25k options, one line each, as
          `name :: type :: default :: first sentence`. Grep this first.
        - `options.json` -- the full upstream records. Don't read it whole;
          pull one out by name:

              jq '."services.nginx.enable"' options.json

        - `options-local.index` -- the `modules.*` options *this repo*
          declares, which no published manual covers. Three fields, not
          four: `name :: type :: description`. Defaults are deliberately
          absent (rendering them is an eval cycle) -- read the module under
          `modules/` for those.
        EOF
      '';

    noctaliaPackage = hey.inputs.noctalia.packages.${system}.default;
    noctaliaDocs =
      pkgs.runCommand "noctalia-docs-${noctaliaPackage.version}" {
        passthru = { inherit (noctaliaPackage) version; };
      } ''
        mkdir -p "$out"
        # --no-preserve=mode or the store's read-only bits come along and
        # the prune below can't touch what it copied.
        cp -r --no-preserve=mode ${hey.inputs.noctalia}/docs/. "$out"/
        # 11 of the 12 megabytes are screenshots, and a screenshot is the
        # one thing in here Claude can't grep.
        find "$out" -type d -name assets -prune -exec rm -rf {} +
        # The top-level notes aren't in docs/ but answer more questions than
        # half of what is. example.toml doubly so -- it's the only complete
        # statement of what config.toml accepts.
        for f in README.md BUILDING.md PACKAGING.md CONTRIBUTING.md example.toml; do
          cp --no-preserve=mode "${hey.inputs.noctalia}/$f" "$out/$f" || true
        done
      '';

    ## Assembly ------------------------------------------------------------

    sources = filterAttrs (_: v: v != null) cfg.resources.sources;

    # How far each tree can be trusted, because "there is a local copy" and "the
    # local copy describes what you have installed" are different claims.
    fidelity = {
      claude-code = "no -- upstream's latest as of the last nixos-rebuild";
      hyprland    = "yes -- the wiki's own ${hyprlandVersion} build";
      janet       = "core-api.md yes; manual/ tracks upstream master";
      nix         = "yes -- nixpkgs' own doc output";
      nixos       = "yes -- upstream's ${config.system.nixos.release} set, plus this repo's modules.*";
      noctalia    = "yes -- the pinned flake revision";
    };

    # An index for claude
    resourcesIndex = pkgs.writeText "claude-resources-README.md" ''
      # Local documentation mirrors

      Offline copies of the docs for tools installed on this machine, built
      by `modules/shell/claude.nix`. Grep before you read: these trees are
      large, and the answer is usually a few lines of one file.

      ```sh
      rg -l 'windowrulev2' /etc/claude-code/resources/hyprland/
      ```

      | Tree | Version | Matches what's installed? |
      |---|---|---|
      ${concatStringsSep "\n" (mapAttrsToList (name: drv:
        "| `${name}` | ${if isAttrs drv then drv.version or "-" else "rolling"} | ${fidelity.${name} or "unknown"} |")
        sources)}

      ## Caveats worth repeating

      - **claude-code/** has no version pin, and isn't even in the nix store:
        `claude-code-docs.service` refills it on every nixos-rebuild and
        leaves it alone in between. The CLI here is
        ${pkgs.claude-code.version}, but these pages are whatever upstream
        published as of the last rebuild. For flag-level questions
        `claude --help` outranks this tree. An empty directory means the
        fetch hasn't succeeded yet --- `systemctl start claude-code-docs`.
        `INDEX.short.txt` is the table of contents (path and title per page);
        `INDEX.txt` adds a sentence per page and is four times larger, so
        grep it rather than reading it.
      - **janet/manual/** is the website's `master`, not ${pkgs.janet.version}.
        `janet/core-api.md` *is* exact -- it's dumped from the installed
        interpreter -- so prefer it for anything in the core library.
      - **nixos/options.json** is tens of megabytes. Use `options.index`,
        then `jq` for the one record you want. This repo's own `modules.*`
        options are in `options-local.index`, not in either of those.
    '';

    resources = pkgs.runCommand "claude-resources" {} ''
      mkdir -p "$out"
      ${concatStringsSep "\n"
        (mapAttrsToList (name: drv: ''ln -s ${drv} "$out"/${name}'') sources)}
      cp ${resourcesIndex} "$out"/README.md
    '';
in {
  options.modules.shell.claude = with types; {
    enable = mkBoolOpt false;

    settings = mkOpt' settingsFormat.type {} ''
      Claude Code managed settings, written to
      /etc/claude-code/managed-settings.d/50-nixos.json.

      config/claude/managed-settings.d/10-defaults.json is the baseline for
      every host; this is where a host or another module adjusts it. Claude
      Code reads the drop-ins in filename order and merges them: a single
      value in a later file replaces the earlier one, lists union, and nested
      blocks (env, permissions, sandbox) merge key by key. So a host can set
      `settings.model = "sonnet"` or add to `settings.permissions.deny`
      without touching the shared file -- but it cannot *remove* a list entry
      the defaults set.

      Keys are documented in settings-reference.md, mirrored under
      /etc/claude-code/resources/claude-code/ when resources are enabled.
    '';

    resources = {
      enable = mkBoolOpt true;

      sources = mkOpt' (attrsOf (nullOr (either str package))) {} ''
        Documentation trees to expose at /etc/claude-code/resources/<name>.
        Set one to null to drop it -- a headless host has no use for the
        Hyprland wiki, and each is a few tens of megabytes.

        A string is symlinked verbatim instead of being built, which is how
        claude-code's rolling mirror stays out of the store.
      '';

      hashes = mkOpt' (attrsOf str) {} ''
        Output hash for the Hyprland wiki, the one doc set scraped from a
        website rather than built from something already in the store.

        It breaks differently from a normal dependency: the derivation is
        fixed-output, so when upstream edits a page the build *fails* with a
        hash mismatch instead of serving stale docs. That's fine here --
        the wiki is versioned, so it only moves when I bump Hyprland. To
        re-pin, take the `got:` hash out of the failure, or ask for it:

          nix build --no-link \
            .#nixosConfigurations.HOST.config.modules.shell.claude.resources.sources.hyprland

        Nothing else in the system depends on it, so a stale pin costs
        nothing until you choose to move it. `resources.enable = false` gets
        you a rebuild in a hurry.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    ## The CLI itself ------------------------------------------------------
    {
      user.packages = with pkgs; [
        claude-code
      ];

      environment.shellAliases = {
        cl  = "claude";
        cls = "claude --model sonnet";
        clo = "claude --model opus";
        clh = "claude --model haiku";
        clf = "claude --model fable";
      };

      # Respect XDG, damn it! The tmpfiles rule is that same directory; claude
      # keeps credentials in there, so nobody else gets to look.
      environment.sessionVariables.CLAUDE_CONFIG_DIR =
        "${config.home.dataDir}/claude";
      systemd.user.tmpfiles.rules = [ "d %h/.local/share/claude 700 - - - -" ];

      environment.etc =
        let claudeDir = "${hey.configDir}/claude";
            dropinDir = "${claudeDir}/managed-settings.d";
            install = sub: dir: entries: mapAttrs'
              (name: _: nameValuePair "claude-code/${sub}${name}" {
                source = "${dir}/${name}";
              })
              entries;
        in install "" claudeDir
            (removeAttrs (builtins.readDir claudeDir) [ "managed-settings.d" ])
          # Claude Code ignores hidden files in the drop-in directory; so do we.
          // install "managed-settings.d/" dropinDir
            (filterAttrs (n: _: !hasPrefix "." n) (builtins.readDir dropinDir));
    }

    (mkIf (cfg.settings != {}) {
      environment.etc."claude-code/managed-settings.d/50-nixos.json".source =
        settingsFormat.generate "claude-managed-settings-50-nixos.json" cfg.settings;
    })

    ## The doc mirrors -----------------------------------------------------
    (mkIf cfg.resources.enable {
      environment.etc."claude-code/resources".source = resources;

      modules.shell.claude.resources = {
        sources = mapAttrs (_: mkDefault) ({
          claude-code = claudeCodeDir;
          janet       = janetDocs;
          nix         = nixManual;
          nixos       = nixosOptions;
        } // optionalAttrs config.modules.hyprland.enable {
          hyprland = hyprlandWiki;
          noctalia = noctaliaDocs;
        });

        hashes.hyprland =
          mkDefault "sha256-kMR/UUQJM+xx6PDFOtDRvFPr6DiB4yTPng0Bkbg/dJ8=";
      };
    })

    # The one tree that can't be a derivation (see claudeCodeDir above): a
    # oneshot that scrapes it into /var/cache, plus the activation hook that
    # pokes it.
    (mkIf (cfg.resources.enable && liveClaudeCodeDocs) {
      systemd.services.claude-code-docs = {
        description = "Refresh the local claude-code documentation mirror";
        documentation = [ "https://code.claude.com/docs" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        # No wantedBy and no timer: the activation script below is the only
        # thing that starts this, so the mirror refreshes when I rebuild and
        # drifts from upstream in between. That's the trade -- a rolling doc
        # set I only pay for when I'm already waiting on nix.
        path = with pkgs; [ bash coreutils curl findutils gnugrep ];
        environment.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        serviceConfig = {
          Type = "oneshot";
          CacheDirectory = baseNameOf claudeCodeCache;
          WorkingDirectory = claudeCodeCache;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          NoNewPrivileges = true;
          Nice = 10;
        };

        script = let dir = baseNameOf claudeCodeDir; in ''
          rm -rf .new urls && mkdir -p .new
          curl -fsSL https://code.claude.com/docs/llms.txt -o .new/INDEX.txt
          grep -oE 'https://code\.claude\.com/docs/en/[^)]+\.md' .new/INDEX.txt \
            | sort -u > urls
          test -s urls || { echo "llms.txt listed no pages" >&2; exit 1; }
          # llms.txt carries a sentence per page (~47KB, ~12k tokens read
          # whole). Claude wants a TOC it can afford to read: section headers
          # plus "path  Title", a quarter of the size, minus the translated
          # mirrors. The long one stays for grep.
          sed -E -e '\#docs/_llms/#d' -e '/^- \[/!{/^#/!d}' \
                 -e 's#^- \[([^]]+)\]\(https://code\.claude\.com/docs/en/([^)]+)\).*#\2  \1#' \
                 .new/INDEX.txt > .new/INDEX.short.txt
          # ~200 pages served one at a time is most of the run; -P8 is polite
          # enough not to get throttled and still finishes in seconds.
          xargs -P8 -I{} sh -c '
            rel=''${1#https://code.claude.com/docs/en/}
            mkdir -p "$(dirname ".new/$rel")"
            curl -fsSL --retry 3 "$1" -o ".new/$rel"
          ' _ {} < urls
          rm -f urls
          # One filesystem, so the swap is two renames: a reader mid-grep sees
          # the old tree or the new one, never half of each.
          rm -rf .old
          if [ -d ${dir} ]; then mv ${dir} .old; fi
          mv .new ${dir}
          rm -rf .old
        '';
      };

      # --no-block, so ~200 page fetches never hold up a switch and a dead
      # network is the unit's failure, not `hey sync`'s exit code.
      #
      # switch-to-configuration exports NIXOS_ACTION for every action; a real
      # boot runs activate straight out of stage 2 with it unset. That's the
      # only honest "rebuild or boot?" test here -- /run/systemd/system lies
      # under systemd stage 1, where activation runs inside the initrd with
      # the initrd's systemd already up.
      system.activationScripts.claudeCodeDocs = ''
        case "''${NIXOS_ACTION:-}" in
          switch|test)
            ${config.systemd.package}/bin/systemctl start --no-block claude-code-docs.service || true
            ;;
        esac
      '';
    })
  ]);
}
