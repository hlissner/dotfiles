(local gears   (require :gears))
(local awful   (require :awful))
(local naughty (require :naughty))
(require :awful.autofocus)

(local wincmd (require :commands.window))
(local tagcmd (require :commands.tag))
(local pa     (require :utils.pulseaudio))
(local input  (require :utils.input))


(fn initialize [bindings]
  ;; Error handling
  ;; Check if awesome encountered an error during startup and fell back to
  ;; another config (This code will only ever execute for the fallback config)
  (let [preset { :timeout 0 :bg "#000000" :fg "#ff0000" :max_height 1080 }]
    (when awesome.startup_errors
      (naughty.notify {:preset preset
                       :title "Oops, there were errors during startup!"
                       :text awesome.startup_errors}))

    (var in-error false)
    (awesome.connect_signal
     "debug::error"
     (fn []
       ;; Make sure we don't go into an endless error loop
       (when (not in-error)
         (set in-error true)
         (naughty.notify {:preset preset
                          :title "Oops, an error happened!"
                          :text (tostring err)})
         (naughty.notify {:preset preset
                          :title "Oops, an error happened!"
                          :text (tostring err)})
         (set in-error false)))))

  (root.keys bindings.global-keys)

  (naughty.notify {:text "Glorious fennel"})
  (gears.wallpaper.set "#282c34"))


(local
 bindings
 {
  :global-keys
  (gears.table.join

   (input.key-group
    "awesome"
    [[:mod] :s hotkeys_popup.show_help "show help"]
    [[:mod :shift] :r awesome.restart "reload config"]
    )

   (input.key-group
    "exec"
    [[:mod] :space (fn [] (awful.util.spawn "rofi -show run")) "app launcher"]
    [[:mod] :e (fn [] (awful.util.spawn "emacsclient -c -n -e '(switch-to-buffer nil)'")) "emacs"]
    [[:mod] :v (fn []
                 (let [option "gopass ls --flat"
                       prompt "rofi -dmenu -p pass"
                       action "xargs --no-run-if-empty gopass show -c"
                       cmd (.. option " | " prompt " | " action)]
                   (awful.spawn.easy_async_with_shell cmd (fn []))))
     "secret vault"]
    [[:mod] :Return (fn [] (awful.spawn "xst")) "open terminal"]
    [[] :XF86AudioMute pa.toggle-muted "⏼ audio muted"]
    [[] :XF86AudioMicMute pa.toggle-mic-mute "⏼ mic muted"]
    [[] :XF86AudioRaiseVolume (fn [] (pa.adjust-volume 5)) "raise volume"]
    [[] :XF86AudioLowerVolume (fn [] (pa.adjust-volume -5)) "lower volume"]
    )

   (input.key-group
    "client"
    [[:mod] :h        (fn [] (awful.client.focus.bydirection :left))  "focus left"]
    [[:mod] :j        (fn [] (awful.client.focus.bydirection :down))  "focus down"]
    [[:mod] :k        (fn [] (awful.client.focus.bydirection :up))    "focus up"]
    [[:mod] :l        (fn [] (awful.client.focus.bydirection :right)) "focus right"]
    [[:mod] :n        (fn [] (awful.client.focus.byidx 1))            "focus next"]
    [[:mod] :p        (fn [] (awful.client.focus.byidx -1))           "focus previous"]
    [[:mod :shift] :j (fn [] (awful.client.swap.byidx 1))             "swap next with previous"]
    [[:mod :shift] :k (fn [] (awful.client.swap.byidx -1))            "swap next with previous"]
    )
   )

  :client-keys
  (gears.table.join
   (input.key-group
    "client"
    [[:mod] :n wincmd.minimize "minimize"]
    [[:mod] :t wincmd.toggle-ontop "⏼ keep on top"]
    [[:mod] :m wincmd.toggle-maximized "⏼ maximize"]
    [[:mod] :f wincmd.toggle-fullscreen "⏼ fullscreen"]
    [[:mod :ctrl] :space awful.client.floating.toggle "⏼ floating"]
    [[:mod :ctrl] :Return wincmd.move-to-master "move to master"]
    [[:mod :ctrl] :m wincmd.toggle-maximize-vertical "⏼ max vertically"]
    [[:mod :shift] :m wincmd.toggle-maximize-horizontal "⏼ max horizontally"]
    [[:mod :shift] :c wincmd.close "close"]
    ))

  :client-buttons
  (gears.table.join
   (input.mousebind [] input.left-click client.mouse-raise)
   (input.mousebind [:mod] input.left-click client.mouse-drag-move)
   (input.mousebind [:mod] input.right-click client.mouse-drag-resize)
   )
  })


;;
(initialize bindings)
