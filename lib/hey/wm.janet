# lib/hey/wm.janet
#
# The compositor, flattened. Everything in bin/hey.d/wm.d asks this instead of
# niri msg, so the tool is named in one place and the commands get back keys
# rather than niri's JSON. Some fields are approximations -- where, the function
# says so.

(import spork/json)
(use ./.)
(use sh)
(import ./vars)

(defn- jq "Run ARGV and decode its JSON." [& argv]
  (json/decode ($< ,;argv) :keywords true))

(defn- niri-json [& args] (jq "niri" "msg" "-j" ;args))


## * Queries

(defn outputs
  ``Every output the compositor knows of, on or off:
  {:name :focused :enabled :x :y :width :height :scale}, in logical pixels.``
  []
  # A map keyed by name (so sorted, for a stable listing), and `logical` is null
  # for an output that's off.
  (let [focused (get (niri-json "focused-output") :name)]
    (sort-by |($0 :name)
      (seq [[name o] :pairs (niri-json "outputs") :let [l (o :logical)]]
        {:name (string name) :focused (= (string name) focused) :enabled (truthy? l)
         :x (get l :x) :y (get l :y) :width (get l :width) :height (get l :height)
         :scale (get l :scale)}))))

(defn focused-output [] (find |($0 :focused) (outputs)))

(defn workspaces
  ``{:id :name :output :active :focused :idx :empty}. active = shown on its
  output; idx is the workspace's position on it.``
  []
  (seq [w :in (niri-json "workspaces")]
    {:id (w :id) :name (w :name) :output (w :output)
     :active (w :is_active) :focused (w :is_focused)
     :idx (w :idx) :empty (nil? (w :active_window_id))}))

(defn focused-workspace [] (find |($0 :focused) (workspaces)))

(defn windows
  ``{:id :app-id :title :pid :focused :floating :workspace :geometry}. geometry
  is [x y w h] in global logical pixels, nil when the window isn't on screen.``
  []
  # niri's positions are relative to the output's view, so an output origin has
  # to be added back on; and a window scrolled off the tape has none.
  (let [outs (tabseq [o :in (outputs)] (o :name) o)
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
                      ww wh]))})))

(defn focused-window [] (find |($0 :focused) (windows)))

(defn visible-windows
  "Windows on a shown workspace, each with a geometry."
  []
  (let [active (tabseq [w :in (workspaces) :when (w :active)] (w :id) true)]
    (filter |(and ($0 :geometry) (get active ($0 :workspace))) (windows))))

(defn layers
  "The namespaces of every mapped layer-shell surface."
  []
  (map |($0 :namespace) (niri-json "layers")))


## * Actions

(defn action
  "Do something to the compositor: ARGV is a `niri msg action` argv."
  [& argv]
  (do? $? niri msg action ,;argv > :null))

(defn toggle-overview [] (action "toggle-overview"))

(defn dpms [on?]
  (action (if on? "power-on-monitors" "power-off-monitors")))

(defn set-output "Turn NAME on or off." [name on?]
  (do? $? niri msg output ,name ,(if on? "on" "off") > :null))


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
