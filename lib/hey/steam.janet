# lib/hey/steam.janet
#
# For talking to Steam and SteamOS (CEF debugging needs to be enabled; if you
# have Decky installed CEF is enabled).

(use ./.)
(use sh)
(import spork/base64)
(import ./romm)
(import ./romm/retroid)

(def remote-steam-dir ".local/share/Steam")

(defn steam-dir []
  (path/join (os/getenv "HOME") remote-steam-dir))

(defn user-id [dir]
  (def ids (filter |(and (not= $0 "0") (peg/match '(* :d+ -1) $0))
                   (os/dir (path/join dir "userdata"))))
  (case (length ids)
    0 (abort "No Steam account under %s/userdata" dir)
    1 (first ids)
    (abort "More than one Steam account under %s/userdata: %s" dir (string/join ids ", "))))

(defn shortcuts-file [dir uid]
  (path/join dir "userdata" uid "config/shortcuts.vdf"))

(defn prefix-dir [dir appid]
  (path/join dir "steamapps/compatdata" (string appid) "pfx/drive_c/users/steamuser"))

(defn prefix-here
  "SHORTCUT's prefix user dir on this machine, when it has one."
  [shortcut]
  (when-let [appid (shortcut :appid)
             dir (prefix-dir (steam-dir) appid)]
    (when (path/directory? dir) dir)))

(def excluded-dirs
  ["Temp" "dxvk" "Microsoft" "UnrealEngine" "openvr" "D3DSCache"
   "NVIDIA" "AMD" "CrashDumps"])

(def excludes
  "Excluded dirs as rsync flags, anchored to the user dir."
  (map |(string "--exclude=/AppData/Local/" $0 "/") excluded-dirs))

(def save-excludes
  "Excluded dirs as paths relative to the user dir, for the zip."
  (map |(string "AppData/Local/" $0) excluded-dirs))

## Binary VDF

(defn read-vdf [bytes]
  (var i 0)
  (defn cstring []
    (def j (or (string/find "\0" bytes i)
               (errorf "vdf: unterminated string at %d" i)))
    (def s (string/slice bytes i j))
    (set i (inc j))
    s)
  (defn node []
    (def out @{})
    (while true
      (when (>= i (length bytes))
        (errorf "vdf: map never closed"))
      (def at i)
      (def type (get bytes i))
      (++ i)
      (when (= type 0x08) (break))
      (def key (cstring))
      (put out key
           (case type
             0x00 (node)
             0x01 (cstring)
             0x02 (let [[a b c d] (slice bytes i (+ i 4))]
                    (set i (+ i 4))
                    (+ a (* b 0x100) (* c 0x10000) (* d 0x1000000)))
             (errorf "vdf: unknown node type 0x%02x at %d" type at))))
    out)
  (def root (node))
  (when (< i (length bytes))
    (errorf "vdf: %d bytes of trailing data" (- (length bytes) i)))
  root)

(defn- field [entry name]
  (or (get entry name)
      # older files spell the keys in lowercase
      (get entry (string/ascii-lower name))))

(defn- strip-quotes [exe]
  (if (and (>= (length exe) 2)
           (string/has-prefix? `"` exe)
           (string/has-suffix? `"` exe))
    (string/slice exe 1 -2)
    exe))

(defn shortcuts
  ``Non-steam shortcuts in BYTES (shortcuts.vdf), in file order.``
  [bytes]
  (def root (or (field (read-vdf bytes) "shortcuts") @{}))
  (seq [k :in (sort-by scan-number (filter scan-number (keys root)))
        :let [e (get root k)]]
    (def exe (or (field e "Exe") ""))
    {:appid (field e "appid")
     :name (or (field e "AppName") "")
     :exe exe
     :exe-path (strip-quotes exe)
     :start-dir (strip-quotes (or (field e "StartDir") ""))
     :launch-options (or (field e "LaunchOptions") "")
     :icon (or (field e "icon") "")}))

(defn find-shortcut
  "The shortcut called NAME (case insensitive); nil otherwise."
  [shortcuts name]
  (or (find |(= name ($0 :name)) shortcuts)
      (let [lower (string/ascii-lower name)]
        (find |(= lower (string/ascii-lower ($0 :name))) shortcuts))))

(defn relocate
  ``Where SHORTCUT's files go when the game dir lands under DEST on another
  machine, as {:dir :exe}. The exe must live under StartDir. The folder keeps
  StartDir's name unless AS says otherwise.``
  [shortcut dest &opt as]
  (def start (string/trimr (shortcut :start-dir) "/"))
  (def exe (shortcut :exe-path))
  (unless (and (not (empty? start))
               (string/has-prefix? "/" start)
               (string/has-prefix? (string start "/") exe))
    (errorf "%s's exe (%s) isn't inside its start dir (%s); nothing to copy"
            (shortcut :name) exe (shortcut :start-dir)))
  (def dir (path/join dest (or as (path/basename start))))
  {:dir dir
   :exe (path/join dir (string/slice exe (inc (length start))))})

## Games from RomM

# Games are served from RomM's "win" platform as archives (zip or 7z) of its
# game install files. GameNative is expected, not DroidDeck or anything else.
# The archive is unpacked locally before transfer to a host.

(defn rom-cache-dir [rom]
  (path :cache "romm" romm/platform (rom :name)))

(defn archive?
  "FILE is an archive push can unpack: a zip or 7z."
  [file]
  (truthy? (index-of (string/ascii-lower (or (path/ext file) "")) [".zip" ".7z"])))

(defn game-exes
  "The exes in DIR and one level down, relative to DIR."
  [dir]
  (defn exe? [f] (= ".exe" (string/ascii-lower (or (path/ext f) ""))))
  (def found @[])
  (each f (sort (os/dir dir))
    (def p (path/join dir f))
    (cond
      (and (exe? f) (path/file? p)) (array/push found f)
      (path/directory? p)
      (each g (sort (os/dir p))
        (when (and (exe? g) (path/file? (path/join p g)))
          (array/push found (path/join f g))))))
  found)

(defn unpack-rom [rom]
  (def dir (rom-cache-dir rom))
  (unless (archive? (rom :file))
    (abort "%s is %s on RomM, not a zip or 7z of an installed game; install it once and archive the result"
           (rom :title) (rom :file)))
  (def local (romm/library-file rom))
  (cond
    (dryrun?)
    (do (if local
          (printf "romm: unpack %s into %s" (path/abbrev local) (path/abbrev dir))
          (printf "romm: download %s and unpack it into %s" (rom :file) (path/abbrev dir)))
        dir)

    (and (path/directory? dir) (not (empty? (game-exes dir))))
    (do (echof :g "%s: already unpacked in %s" (rom :title) (path/abbrev dir))
        dir)

    (do
      ($? rm -rf ,dir)
      ($ mkdir -p ,dir)
      (def archive (or local (string dir (path/ext (rom :file)))))
      (if local
        (echof :g "%s: unpacking %s" (rom :title) (path/abbrev local))
        (echof :g "%s: downloading %s from RomM" (rom :title) (rom :file)))
      (defer (unless local (ignore-errors (os/rm archive)))
        (unless local (romm/fetch-rom rom archive))
        # 7zz reads zips too; one extractor, and no unzip to keep around.
        (unless ($? "7zz" x -y -bso0 -bsp0 ,(string "-o" dir) ,archive)
          ($? rm -rf ,dir)
          (abort "Couldn't unpack %s" (rom :file))))
      (def entries (os/dir dir))
      (when (and (= 1 (length entries)) (path/directory? (path/join dir (first entries))))
        # Out and back in: a dir can't be replaced by its own child in place.
        (def tmp (string dir ".unwrap"))
        ($ mv ,(path/join dir (first entries)) ,tmp)
        ($ rm -rf ,dir)
        ($ mv ,tmp ,dir))
      dir)))

(defn romm-game
  ``ROM, unpacked at DIR, in the shape of a shortcut ({:name :start-dir
  :exe-path :appid :icon}), which is what push copies and registers. SHORTCUT
  is mine of the same name, if any: it lends its name, exe, art and prefix.
  EXE, relative to DIR, overrides the exe; with neither, DIR must hold exactly
  one.``
  [rom dir &named shortcut exe]
  (def name (if shortcut (shortcut :name) (rom :title)))
  (def theirs
    (when shortcut
      (def start (string/trimr (shortcut :start-dir) "/"))
      (def p (shortcut :exe-path))
      (when (string/has-prefix? (string start "/") p)
        (string/slice p (inc (length start))))))
  (def rel
    (cond
      exe
      (if (or (dryrun?) (path/file? (path/join dir exe)))
        exe
        (abort "%s: no %s in %s" name exe (path/abbrev dir)))

      (and theirs (or (dryrun?) (path/file? (path/join dir theirs))))
      theirs

      (let [exes (if (path/directory? dir) (game-exes dir) @[])]
        (case (length exes)
          1 (first exes)
          0 (abort "%s: no exe in %s; -e EXE says which%s" name (path/abbrev dir)
                   (if (dryrun?) " (nothing is unpacked under dry-run)" ""))
          (abort "%s: more than one exe in %s; -e says which: %s" name (path/abbrev dir)
                 (string/join exes ", "))))))
  {:name name
   :start-dir dir
   :exe-path (path/join dir rel)
   :appid (when shortcut (shortcut :appid))
   :icon (when shortcut (shortcut :icon))})

## Artwork

# SteamClient.Apps.SetCustomArtworkForApp's asset types, by the grid/ filename
# suffix Steam stores each under.
(def- asset-types
  [["p" 0] ["_hero" 1] ["_logo" 2] ["" 3] ["_icon" 4]])

(defn art-globs
  "Shell globs for everything grid/ might hold for APPID, quoted for a remote sh."
  [dir uid appid]
  (seq [[suffix] :in asset-types]
    (string (shell-quote (path/join dir "userdata" uid "config/grid" (string appid suffix))) ".*")))

(defn artwork
  ``APPID's custom art under DIR's grid/, as @[{:type :ext :path}] in asset type
  order. ICON, the shortcut's own icon path, stands in for a missing _icon file.
  png and jpg only; CEF won't accept anything else.``
  [dir uid appid &opt icon]
  (def grid (path/join dir "userdata" uid "config/grid"))
  (def found @[])
  (each [suffix type] asset-types
    (def file
      (or (find path/file?
                (seq [ext :in ["png" "jpg"]]
                  (path/join grid (string appid suffix "." ext))))
          (when (and (= type 4) icon (path/file? icon)
                     (index-of (path/ext icon) [".png" ".jpg"]))
            icon)))
    (when file
      (array/push found {:type type
                         :ext (string/slice (path/ext file) 1)
                         :path file})))
  found)

(defn encode-art
  "ART (from artwork) as the {type {:data :ext}} table register-js wants."
  [art]
  (tabseq [{:type type :ext ext :path file} :in art]
    (string type) {:data (base64/encode (string (slurp file))) :ext ext}))

## The JS Steam runs

(defn register-js
  ``Register a shortcut in Steam for a non-steam game.
  Returns {appid created exe}.``
  [{:name name :exe exe :start-dir start-dir :launch-options launch-options
    :compat compat :art art}]
  (string
   "(async () => {"
   " const name = " (json/encode name) ";"
   " const exe = " (json/encode exe) ";"
   " const startDir = " (json/encode start-dir) ";"
   " const launchOptions = " (json/encode (or launch-options "")) ";"
   " const compat = " (json/encode (or compat "")) ";"
   " const art = " (json/encode (or art {})) ";"
   " const existing = collectionStore.allAppsCollection.allApps"
   "   .find(a => a.app_type === 1073741824 && a.display_name === name);"
   " const appid = existing ? existing.appid"
   "   : await SteamClient.Apps.AddShortcut(name, exe, startDir, launchOptions);"
   " if (!appid) throw new Error('AddShortcut returned ' + appid);"
   " let oldExe = exe;"
   " if (existing) {"
   "   let d = appDetailsStore.GetAppDetails(appid);"
   "   if (!d) { await appDetailsStore.RequestAppDetails(appid); d = appDetailsStore.GetAppDetails(appid); }"
   "   if (d) oldExe = d.strShortcutExe.replace(/^\"(.*)\"$/, '$1');"
   # The files just landed at exe; the shortcut follows them, and keeps its
   # appid, so the prefix and the saves come along.
   "   if (oldExe !== exe) {"
   "     SteamClient.Apps.SetShortcutExe(appid, exe);"
   "     SteamClient.Apps.SetShortcutStartDir(appid, startDir);"
   "   }"
   " }"
   # Older clients named a new shortcut after its exe
   " if (!existing) SteamClient.Apps.SetShortcutName(appid, name);"
   " SteamClient.Apps.SetShortcutLaunchOptions(appid, launchOptions);"
   " if (compat) SteamClient.Apps.SpecifyCompatTool(appid, compat);"
   " for (const [type, {data, ext}] of Object.entries(art))"
   "   await SteamClient.Apps.SetCustomArtworkForApp(appid, data, ext, Number(type));"
   " return {appid, created: !existing, exe: oldExe};"
   "})()"))

## The CEF debugger

# A hand-rolled websocket client to talk to Steam's CEF debugger on the remote
# (emudeck binds it on localhost so it won't be directly reachable over LAN).
# Exit codes:
#   3 = no SharedJSContext
#   2 = no debugger
#   1 = JS error
(def cdp-py `
import base64, json, os, socket, struct, sys, urllib.request
from urllib.parse import urlparse

js = sys.stdin.read()
targets = None
for port in (8080, 8081):
    try:
        with urllib.request.urlopen("http://127.0.0.1:%d/json" % port, timeout=5) as r:
            targets = json.load(r)
        break
    except OSError:
        pass
if targets is None:
    print("no CEF debugger on 127.0.0.1:8080", file=sys.stderr)
    sys.exit(2)
target = next((t for t in targets if t.get("title") == "SharedJSContext"), None)
if target is None:
    print("no SharedJSContext target; is Steam still starting?", file=sys.stderr)
    sys.exit(3)

url = urlparse(target["webSocketDebuggerUrl"])
sock = socket.create_connection((url.hostname, url.port), timeout=120)
key = base64.b64encode(os.urandom(16)).decode()
sock.sendall(("GET %s HTTP/1.1\r\nHost: %s:%d\r\nUpgrade: websocket\r\n"
              "Connection: Upgrade\r\nSec-WebSocket-Key: %s\r\n"
              "Sec-WebSocket-Version: 13\r\n\r\n"
              % (url.path, url.hostname, url.port, key)).encode())
buf = b""
while b"\r\n\r\n" not in buf:
    chunk = sock.recv(4096)
    if not chunk:
        print("debugger hung up during the handshake", file=sys.stderr)
        sys.exit(2)
    buf += chunk
head, buf = buf.split(b"\r\n\r\n", 1)
if not head.startswith(b"HTTP/1.1 101"):
    print(head.decode(errors="replace"), file=sys.stderr)
    sys.exit(2)

def send(opcode, payload):
    n = len(payload)
    head = bytes([0x80 | opcode])
    if n < 126:
        head += bytes([0x80 | n])
    elif n < 65536:
        head += bytes([0x80 | 126]) + struct.pack(">H", n)
    else:
        head += bytes([0x80 | 127]) + struct.pack(">Q", n)
    mask = os.urandom(4)
    # Clients must mask. Byte by byte is seconds for a hero image; as one big
    # int, nothing.
    masked = (int.from_bytes(payload, "big")
              ^ int.from_bytes((mask * (n // 4 + 1))[:n], "big")).to_bytes(n, "big")
    sock.sendall(head + mask + masked)

def recv(n):
    global buf
    while len(buf) < n:
        chunk = sock.recv(65536)
        if not chunk:
            print("debugger hung up", file=sys.stderr)
            sys.exit(2)
        buf += chunk
    out, buf = buf[:n], buf[n:]
    return out

def frame():
    b1, b2 = recv(2)
    n = b2 & 0x7F
    if n == 126:
        n = struct.unpack(">H", recv(2))[0]
    elif n == 127:
        n = struct.unpack(">Q", recv(8))[0]
    mask = recv(4) if b2 & 0x80 else None
    data = recv(n)
    if mask:
        data = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
    return b1 & 0x80, b1 & 0x0F, data

send(1, json.dumps({"id": 1, "method": "Runtime.evaluate",
                    "params": {"expression": js, "awaitPromise": True,
                               "returnByValue": True}}).encode())
message = b""
while True:
    fin, opcode, data = frame()
    if opcode == 9:
        send(10, data)
    elif opcode == 8:
        print("debugger closed the connection", file=sys.stderr)
        sys.exit(2)
    elif opcode in (0, 1):
        message += data
        if fin:
            reply = json.loads(message)
            message = b""
            if reply.get("id") == 1:
                break
sock.close()
result = reply.get("result", {})
if "exceptionDetails" in result:
    exc = result["exceptionDetails"].get("exception", {})
    print(exc.get("description") or result["exceptionDetails"].get("text"), file=sys.stderr)
    sys.exit(1)
if "error" in reply:
    print(reply["error"].get("message"), file=sys.stderr)
    sys.exit(1)
print(json.dumps(result.get("result", {}).get("value")))
`)

(defn remote-home [host]
  (def out @"")
  (unless ($? ssh ,host `printf %s "$HOME"` > ,out > [stderr :null])
    (abort "Can't reach %s over ssh" host))
  (string out))

(defn remote-shortcuts [host &opt uid]
  (default uid (user-id (steam-dir)))
  (def out @"")
  (unless ($? ssh ,host ,(string "cat " (shell-quote (shortcuts-file remote-steam-dir uid)))
              > ,out > [stderr :null])
    (abort "No shortcuts.vdf for account %s on %s" uid host))
  (shortcuts out))

(defn remote-has-prefix?
  "Whether APPID's Proton prefix exists on HOST."
  [host appid]
  ($? ssh ,host ,(string "test -d " (shell-quote (prefix-dir remote-steam-dir appid)))))

(defn ensure-debugging
  ``Make sure Steam on HOST was started with its debugger on.``
  [host]
  (def marker ".steam/steam/.cef-enable-remote-debugging")
  (def out @"")
  (unless ($? ssh ,host ,(string "test -e " marker " || { touch " marker " && echo new; }") > ,out)
    (abort "Couldn't check for Steam's debugger marker on %s" host))
  (when (string/find "new" out)
    (abort (string "Enabled Steam's CEF debugger on %s. Restart Steam there (`steam -shutdown`, "
                   "or Settings > System > Developer > CEF Remote Debugging) and run this again.")
           host)))

(defn cdp-eval
  "Execute JS on HOST's Steam client through the CEF debugger."
  [host js]
  (def out @"")
  (def err @"")
  (unless ($? ssh ,host ,(string "python3 -I -c " (shell-quote cdp-py))
              < ,(buffer js) > ,out > [stderr err])
    (abort "Steam on %s: %s" host (string/trim (string err))))
  (json/decode (string out) :keywords true))

(def libraries-js
  "Steam's libraries on the remote, as [{path default mounted}]."
  (string "SteamClient.InstallFolder.GetInstallFolders().then(fs => fs.map(f =>"
          " ({path: f.strFolderPath, default: f.bIsDefaultFolder, mounted: f.bIsMounted})))"))

(defn remote-games-dir [host home]
  (def lib (find |(and ($0 :default) ($0 :mounted)) (cdp-eval host libraries-js)))
  (if (or (nil? lib) (= (lib :path) (path/join home remote-steam-dir)))
    (path/join home "Games")
    (path/join (lib :path) "Games")))

(def remove-js
  "JS to drop shortcut APPID from the running Steam."
  (fn [appid] (string "SteamClient.Apps.RemoveShortcut(" appid ")")))


## Saves through RomM

# One leg of a sync: pack the prefix's user dir, compare it with the save RomM
# holds, and either hand back a zip to upload or unpack RomM's. It runs on
# whichever machine has the prefix -- here, or over ssh like cdp-py -- and
# never touches the network: the request on stdin carries RomM's zip when
# there is one, the reply on stdout carries ours when it should be uploaded.
#
# Newer wins, by the newest file either side rather than by RomM's upload
# clock: the zip's comment records it, so a Deck that played since the last
# sync isn't clobbered by the upload push made a second earlier. Identical
# contents (RomM's own hash recipe) are a no-op whatever the clocks say.
# Nothing is ever deleted; unpacking only writes.
(def sync-py `# hey:romm-saves
import base64, calendar, hashlib, io, json, os, sys, time, zipfile
from datetime import datetime, timezone

LIMIT = 512 * 1024 * 1024  # RomM's cap on an asset

req = json.load(sys.stdin)
root = req["dir"]
exclude = tuple(e.rstrip("/") + "/" for e in req.get("exclude", []))
direction = req["direction"]
force = bool(req.get("force"))
mkpath = bool(req.get("mkpath"))
dry = bool(req.get("dry_run"))
latest = req.get("latest")
server_zip = base64.b64decode(req["server_zip"]) if req.get("server_zip") else None

def fail(msg, code=1):
    print(msg, file=sys.stderr)
    sys.exit(code)

def reply(action, reason=None, **more):
    print(json.dumps({"action": action, "reason": reason, **more}))
    sys.exit(0)

def pack():
    buf = io.BytesIO()
    n = 0
    newest = 0.0
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for base, dirs, files in os.walk(root):
            rel = os.path.relpath(base, root)
            rel = "" if rel == "." else rel + "/"
            dirs[:] = sorted(d for d in dirs
                             if not (rel + d + "/").startswith(exclude)
                             and not os.path.islink(os.path.join(base, d)))
            for f in sorted(files):
                p = os.path.join(base, f)
                if os.path.islink(p) or not os.path.isfile(p):
                    continue
                st = os.stat(p)
                newest = max(newest, st.st_mtime)
                zi = zipfile.ZipInfo(rel + f, time.gmtime(st.st_mtime)[:6])
                zi.compress_type = zipfile.ZIP_DEFLATED
                with open(p, "rb") as fh:
                    zf.writestr(zi, fh.read())
                n += 1
        zf.comment = json.dumps({"mtime": newest, "files": n}).encode()
    if buf.tell() > LIMIT:
        fail(f"{root} packs to over 512 MiB, RomM's limit")
    return buf.getvalue(), n, newest

def content_hash(data):
    # RomM's: each entry's md5, keyed by name, sorted; md5 of that list.
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        parts = []
        for name in sorted(zf.namelist()):
            if name.endswith("/"):
                continue
            h = hashlib.md5()
            with zf.open(name) as entry:
                while chunk := entry.read(65536):
                    h.update(chunk)
            parts.append(f"{name}:{h.hexdigest()}")
    return hashlib.md5("\n".join(parts).encode()).hexdigest()

def updated_at():
    s = latest["updated_at"].replace("Z", "+00:00")
    t = datetime.fromisoformat(s)
    if t.tzinfo is None:
        t = t.replace(tzinfo=timezone.utc)
    return t.timestamp()

def server_mtime(data):
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        try:
            return float(json.loads(zf.comment.decode())["mtime"])
        except (ValueError, KeyError, TypeError):
            pass
        stamps = [calendar.timegm(zi.date_time) for zi in zf.infolist() if not zi.filename.endswith("/")]
    return float(max(stamps)) if stamps else updated_at()

def unpack(data):
    n = 0
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        for zi in zf.infolist():
            name = zi.filename
            if name.startswith("/") or "\\" in name or ".." in name.split("/"):
                fail(f"refusing zip entry {name!r}")
            if name.endswith("/"):
                continue
            p = os.path.join(root, name)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with zf.open(zi) as src, open(p, "wb") as dst:
                dst.write(src.read())
            t = calendar.timegm(zi.date_time)
            os.utime(p, (t, t))
            n += 1
    return n

if direction not in ("upload", "download"):
    fail(f"bad direction {direction!r}")
exists = os.path.isdir(root)
if not exists and not (direction == "download" and mkpath):
    reply("skip", "no-dir")
if latest is None:
    if direction == "download":
        reply("skip", "no-save")
    data, n, newest = pack()
    if n == 0:
        reply("skip", "empty", files=0)
    reply("upload", files=n, hash=content_hash(data), mtime=newest,
          **({} if dry else {"zip": base64.b64encode(data).decode()}))
if direction == "download" and server_zip is None:
    fail("RomM's save was not fetched")
if exists:
    data, n, newest = pack()
    digest = content_hash(data)
    if digest == latest.get("content_hash"):
        reply("noop", files=n, hash=digest, mtime=newest)
else:
    data, n, newest, digest = None, 0, 0.0, None
smt = server_mtime(server_zip) if server_zip is not None else updated_at()
if direction == "upload":
    if n == 0:
        reply("skip", "empty", files=0)
    if force or newest > smt:
        reply("upload", files=n, hash=digest, mtime=newest, server_mtime=smt,
              **({} if dry else {"zip": base64.b64encode(data).decode()}))
    reply("skip", "server-newer", files=n, hash=digest, mtime=newest, server_mtime=smt)
if force or smt > newest:
    if not dry:
        os.makedirs(root, exist_ok=True)
        n = unpack(server_zip)
    reply("download", files=n, hash=digest, mtime=newest, server_mtime=smt)
reply("skip", "side-newer", files=n, hash=digest, mtime=newest, server_mtime=smt)
`)

(defn sync-saves
  ``Run sync-py on REQUEST (see above), here or on HOST, and return its reply.``
  [request &named host]
  (def out @"")
  (def err @"")
  (def in (buffer (json/encode request)))
  (unless (if host
            ($? ssh ,host ,(string "python3 -I -c " (shell-quote sync-py)) < ,in > ,out > [stderr err])
            ($? python3 -I -c ,sync-py < ,in > ,out > [stderr err]))
    (abort "Saves %s: %s" (if host (string "on " host) "here") (string/trim (string err))))
  (json/decode (string out) true true))

(defn save-name
  "What ROM's save is called on RomM."
  [rom]
  (string (rom :name) ".zip"))

(defn find-rom
  "NAME's ROM on RomM's win platform, or an abort that says where to put it."
  [name &opt pid]
  (or (romm/find-rom [name (retroid/folder-name name)] pid)
      (abort "No ROM called %q on RomM's %s platform. Add %s/roms/%s.* to its library, rescan, and try again"
             name romm/platform romm/platform name)))

(defn romm-entries
  ``RomM's side of every game in NAMES, as {:rom :latest :zip} by name: the
  ROM, its newest proton save and that save's bytes. All looked up first, so
  a game RomM doesn't know stops the run before anything has moved. ROMS, by
  name, are the ones already looked up.``
  [names &named roms]
  (default roms {})
  (def pid (unless (all |(roms $0) names) (romm/platform-id)))
  (tabseq [name :in names]
    name
    (let [rom (or (roms name) (find-rom name pid))
          latest (romm/latest-save (rom :id))]
      {:rom rom
       :latest latest
       :zip (when latest (romm/fetch-save (latest :id)))})))

(defn romm-saves
  ``One leg of NAME's save sync through RomM: DIRECTION (:upload or :download)
  between DIR, the prefix's user dir here or on HOST, and ENTRY, RomM's side
  of it ({:rom :latest :zip}, as romm-entries makes them). Says what it did,
  and returns the entry as RomM holds it afterwards, for the next leg.``
  [name dir entry &named host direction force? mkpath?]
  (def {:rom rom :latest latest :zip server-zip} entry)
  (def side (or host "here"))
  (def where (if host (string "on " host) "here"))
  (def file-name (save-name rom))
  (def verb (if (= direction :upload) "upload" "download"))
  (if (and host (dryrun?))
    # Never ssh under dry-run; say what the leg would do.
    (do (printf "romm: %s %ss %s %s %s" host verb file-name (if (= direction :upload) "from" "into") dir)
        entry)
    (do
      (def reply
        (sync-saves {:dir dir :exclude save-excludes :direction verb
                     :force (truthy? force?) :mkpath (truthy? mkpath?) :dry_run (dryrun?)
                     :latest (when latest {:content_hash (latest :content_hash)
                                           :updated_at (latest :updated_at)})
                     :server_zip (when server-zip (base64/encode (string server-zip)))}
                    :host host))
      (case (reply :action)
        "upload"
        (if (dryrun?)
          (do (printf "romm: upload %s from %s (%d files)" file-name where (reply :files))
              entry)
          (let [bytes (base64/decode (reply :zip))
                save (romm/upload-save (rom :id) file-name bytes)]
            (echof :g "%s: %s → RomM (%d files, save %d)" name side (reply :files) (save :id))
            {:rom rom :latest save :zip bytes}))

        "download"
        (do (echof :g "%s: RomM → %s (%d files)" name side (reply :files))
            entry)

        "noop"
        (do (echof :g "%s: %s and RomM already match" name side)
            entry)

        "skip"
        (do (case (reply :reason)
              "no-dir" (if host
                         (echof :warn "%s has no prefix on %s yet. Launch it there once, then push again (or --seed)" name host)
                         (echof :warn "%s has no prefix here (never launched?); no saves to send" name))
              "empty" (echof :warn "%s's prefix %s holds no files; nothing to send" name where)
              "no-save" (echof :warn "%s has no proton save on RomM yet" name)
              "server-newer" (echof :warn "RomM's %s is newer than %s's saves; --force to overwrite it" file-name name)
              "side-newer" (echof :warn "%s's saves %s are newer than RomM's; --force to overwrite them" name where)
              (echof :warn "%s: skipped (%s)" name (reply :reason)))
            entry)

        (abort "%s: sync-py answered %q" name (reply :action))))))
