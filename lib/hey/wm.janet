# lib/hey/wm.janet
#
# A library for interacting with Niri and Noctalia services

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

(defn workspaces
  ``{:id :name :output :active :focused :idx :empty}. active = shown on its
  output; idx is the workspace's position on it.``
  []
  (seq [w :in (niri-json "workspaces")]
    {:id (w :id) :name (w :name) :output (w :output)
     :active (w :is_active) :focused (w :is_focused)
     :idx (w :idx) :empty (nil? (w :active_window_id))}))

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



## * Actions

(defn action
  "Do something to the compositor: ARGV is a `niri msg action` argv."
  [& argv]
  (do? $? niri msg action ,;argv > :null))


## * Selection

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
               "window" (let [active (tabseq [w :in (workspaces) :when (w :active)] (w :id) true)
                              boxes (string/join
                                      (seq [w :in (windows)
                                            :when (and (w :geometry) (get active (w :workspace)))
                                            :let [[x y bw bh] (w :geometry)]]
                                        (fmt "%d,%d %dx%d\n" x y bw bh))
                                      "")]
                          ($? slurp -r ,;args < ,boxes > ,out))
               (abort "Unknown target: %s" target))]
      (when ok
        (def geom (string/chomp out))
        (vars/set :wm.slurp.last geom)
        geom))))
