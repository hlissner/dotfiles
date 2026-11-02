# lib/hey/steam.janet
#
# For talking to Steam and SteamOS (CEF debugging needs to be enabled; if you
# have Decky installed CEF is enabled).

(use ./.)
(use sh)
(import spork/base64)

# SteamOS keeps it in the plain place, and ~/.steam/steam points at it.
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

(def excludes
  (map |(string "--exclude=/AppData/Local/" $0 "/")
       ["Temp" "dxvk" "Microsoft" "UnrealEngine" "openvr" "D3DSCache"
        "NVIDIA" "AMD" "CrashDumps"]))

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
  machine, as {:dir :exe}. The exe must live under StartDir.``
  [shortcut dest]
  (def start (string/trimr (shortcut :start-dir) "/"))
  (def exe (shortcut :exe-path))
  (unless (and (not (empty? start))
               (string/has-prefix? "/" start)
               (string/has-prefix? (string start "/") exe))
    (errorf "%s's exe (%s) isn't inside its start dir (%s); nothing to copy"
            (shortcut :name) exe (shortcut :start-dir)))
  (def dir (path/join dest (path/basename start)))
  {:dir dir
   :exe (path/join dir (string/slice exe (inc (length start))))})

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
