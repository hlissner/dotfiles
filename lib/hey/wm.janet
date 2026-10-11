# lib/hey/wm.janet
#
# The compositor, flattened. Everything in bin/hey.d/wm.d asks this instead of
# hyprctl or niri msg, so one command serves both desktops; the only place
# either tool is named is in here. Every query returns the same keys under both,
# which means some fields are approximations -- where, the function says so.

(import spork/json)
(use ./.)
(use sh)
(import ./vars)

(defn- jq "Run ARGV and decode its JSON." [& argv]
  (json/decode ($< ,;argv) :keywords true))

(defn- hypr-json [& args] (jq "hyprctl" "-j" ;args))
(defn- niri-json [& args] (jq "niri" "msg" "-j" ;args))


## * Queries

(defn outputs
  ``Every output the compositor knows of, on or off:
  {:name :focused :enabled :x :y :width :height :scale}, in logical pixels.``
  []
  (case (wm)
    :hypr (seq [m :in (hypr-json "monitors" "all")]
            {:name (m :name) :focused (m :focused) :enabled (not (m :disabled))
             :x (m :x) :y (m :y)
             :width (math/floor (/ (m :width) (m :scale)))
             :height (math/floor (/ (m :height) (m :scale)))
             :scale (m :scale)})
    # A map keyed by name (so sorted, for a stable listing), and `logical` is
    # null for an output that's off.
    :niri (let [focused (get (niri-json "focused-output") :name)]
            (sort-by |($0 :name)
              (seq [[name o] :pairs (niri-json "outputs") :let [l (o :logical)]]
                {:name (string name) :focused (= (string name) focused) :enabled (truthy? l)
                 :x (get l :x) :y (get l :y) :width (get l :width) :height (get l :height)
                 :scale (get l :scale)})))))

(defn focused-output [] (find |($0 :focused) (outputs)))

(defn workspaces
  ``{:id :name :output :active :focused}. active = shown on its output. Under
  hyprland a raised special workspace is shown *over* the regular one, so both
  are active and the special has the focus -- which hyprctl activeworkspace
  pretends isn't there.``
  []
  (case (wm)
    :hypr (catseq [m :in (hypr-json "monitors")
                   # No special shown is id 0, or no id at all, depending
                   # on the build.
                   :let [a (m :activeWorkspace) s (m :specialWorkspace)
                         plain? (zero? (get s :id 0))]]
            [{:id (a :id) :name (a :name) :output (m :name)
              :active true :focused (and (m :focused) plain?)}
             ;(if plain? []
                [{:id (s :id) :name (s :name) :output (m :name)
                  :active true :focused (m :focused)}])])
    :niri (seq [w :in (niri-json "workspaces")]
            {:id (w :id) :name (w :name) :output (w :output)
             :active (w :is_active) :focused (w :is_focused)})))

(defn focused-workspace [] (find |($0 :focused) (workspaces)))

(defn windows
  ``{:id :app-id :title :pid :focused :floating :workspace :geometry}. geometry
  is [x y w h] in global logical pixels, nil when the window isn't on screen.``
  []
  (case (wm)
    :hypr (seq [c :in (hypr-json "clients") :when (c :mapped)]
            {:id (c :address) :app-id (c :class) :title (c :title) :pid (c :pid)
             :focused (zero? (c :focusHistoryID)) :floating (c :floating)
             :workspace (get-in c [:workspace :id])
             :geometry [;(c :at) ;(c :size)]})
    # niri's positions are relative to the output's view, so an output origin
    # has to be added back on; and a window scrolled off the tape has none.
    :niri (let [outs (tabseq [o :in (outputs)] (o :name) o)
                wss  (tabseq [w :in (workspaces)] (w :id) w)]
            (seq [w :in (niri-json "windows")
                  :let [l (w :layout)
                        ws (get wss (w :workspace_id))
                        o (get outs (get ws :output))
                        pos (l :tile_pos_in_workspace_view)]]
              {:id (w :id) :app-id (w :app_id) :title (w :title) :pid (w :pid)
               :focused (w :is_focused) :floating (w :is_floating)
               :workspace (w :workspace_id)
               :geometry (when (and pos (get o :enabled) (get ws :active))
                           (let [[ox oy] (l :window_offset_in_tile)
                                 [ww wh] (l :window_size)]
                             [(math/round (+ (o :x) (pos 0) ox))
                              (math/round (+ (o :y) (pos 1) oy))
                              ww wh]))}))))

(defn focused-window [] (find |($0 :focused) (windows)))

(defn visible-windows
  "Windows on a shown workspace, each with a geometry."
  []
  (let [active (tabseq [w :in (workspaces) :when (w :active)] (w :id) true)]
    (filter |(and ($0 :geometry) (get active ($0 :workspace))) (windows))))

(defn layers
  "The namespaces of every mapped layer-shell surface."
  []
  (case (wm)
    :hypr (catseq [[_ mon] :pairs (hypr-json "layers")
                   [_ level] :pairs (mon :levels)]
            (map |($0 :namespace) level))
    :niri (map |($0 :namespace) (niri-json "layers"))))


## * Actions

(defn action
  ``Do something to the compositor. HYPR is a hyprctl dispatch argv, or
  {:eval LUA}; NIRI is a `niri msg action` argv. Whichever the desktop isn't is
  ignored, so a caller spells out both.``
  [&named hypr niri]
  (case (wm)
    :hypr (if (dictionary? hypr)
            (do? $? hyprctl eval ,(hypr :eval) > :null)
            (do? $? hyprctl dispatch ,;hypr > :null))
    :niri (do? $? niri msg action ,;niri > :null)))

(defn toggle-overview
  "ALL? spreads every workspace out; niri's overview always does."
  [&opt all?]
  (action :hypr {:eval (if all?
                         `hey.plugins.so.overview("toggle all", 0.4)()`
                         `hey.plugins.so.overview("toggle")()`)}
          :niri ["toggle-overview"]))

(defn dpms [on?]
  (action :hypr {:eval (fmt `hl.dispatch(hl.dsp.dpms({ action = %q }))`
                            (if on? "enable" "disable"))}
          :niri [(if on? "power-on-monitors" "power-off-monitors")]))

(defn set-output
  ``Turn NAME on or off. Hyprland forgets a disabled monitor's mode, so turning
  one on reapplies its rule from hey.info.hypr.monitors.``
  [name on?]
  (case (wm)
    :hypr (let [rule (or (find |(= ($0 :output) name) (or (flake/info :hypr :monitors) []))
                         {:output name})
                fields (seq [k :in [:output :mode :position] :let [v (get rule k)] :when v]
                         (fmt "%s = %q" k v))]
            (do? $? hyprctl eval
                 ,(fmt "hl.monitor({ %s, scale = %s, disabled = %s })"
                       (string/join fields ", ")
                       (string (get rule :scale 1))
                       (if on? "false" "true"))
                 > :null))
    :niri (do? $? niri msg output ,name ,(if on? "on" "off") > :null)))


## * Selection

(defn parse-geometry
  ``Parse "X,Y WxH" into [x y w h] or nil.``
  [geom]
  (peg/match (peg! '(* (number (* (? "-") :d+)) "," (number (* (? "-") :d+))
                      " " (number :d+) "x" (number :d+) -1))
             (string geom)))

(defn select
  ``A slurp selection ("X,Y WxH") for TARGET: region (the default), output,
  window, or last. ARGS go to slurp. Cached as the wm.slurp.last var, which is
  what last reads back; nil when the user cancels or there's nothing cached.``
  [&opt target & args]
  (default target "region")
  (if (= target "last")
    (vars/get :wm.slurp.last)
    (let [out @""
          ok (case target
               "output" ($? slurp -o ,;args > ,out)
               "region" ($? slurp ,;args > ,out)
               # slurp -r picks among boxes fed on stdin, so the windows are
               # what's on screen, not what's under the cursor.
               "window" (let [boxes (string/join
                                     (seq [w :in (visible-windows)
                                           :let [[x y bw bh] (w :geometry)]]
                                       (fmt "%d,%d %dx%d\n" x y bw bh))
                                     "")]
                          ($? slurp -r ,;args < ,boxes > ,out))
               (abort "Unknown target: %s" target))]
      (when ok
        (def geom (string/chomp out))
        (vars/set :wm.slurp.last geom)
        geom))))
