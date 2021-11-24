;; If LuaRocks is installed, make sure that packages installed through it are
;; found (e.g. lgi). If LuaRocks is not installed, do nothing.
(pcall :require "luarocks.loader")

;; ...
(local gears     (require :gears))
(local beautiful (require :beautiful))
(local awful     (require :awful))
(local naughty   (require :naughty))
(local hotkeys_popup (require :awful.hotkeys_popup))
(local wibox     (require :wibox))
(local menubar   (require :menubar))

;; ...
(fn initialize []
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
     (fn [err]
       ;; Make sure we don't go into an endless error loop
       (when (not in-error)
         (set in-error true)
         (naughty.notify {:preset preset
                          :title "Oops, an error happened!"
                          :text (tostring err)})
         (naughty.notify {:preset preset
                          :title "Oops, an error happened!"
                          :text (tostring err)})
         (set in-error false))))))

(initialize)
;; Sensible refocusing behavior when killing/creating clients
(require :awful.autofocus)
;; Enable hotkeys help widget for VIM and other apps when client with a matching
;; name is opened:
(require :awful.hotkeys_popup.keys)

;; This is used later as the default terminal and editor to run.
(local terminal "xst")
(local editor (or (os.getenv "EDITOR") "vim"))
(local editor_cmd (.. terminal " -e " editor))
(local modkey "Mod4")

;; Themes define colours, icons, font and wallpapers.
(beautiful.init (.. (gears.filesystem.get_themes_dir) "default/theme.lua"))

(local myawesomemenu
       {{ "hotkeys"     (fn [] (hotkeys_popup.show_help nil (awful.screen.focused))) }
        { "manual"      (.. terminal " -e man awesome") }
        { "edit config" (.. editor_cmd " " awesome.conffile) }
        { "restart" awesome.restart }
        })

(local mymainmenu
       { :items [[ "awesome" myawesomemenu beautiful.awesome_icon ]
                 [ "open terminal" terminal ]] })

(local mylauncher (awful.widget.launcher { :image beautiful.awesome_icon :menu mymainmenu }))

(local mykeyboardlayout (awful.widget.keyboardlayout))

(local mytextclock (wibox.widget.textclock))

(local taglist_buttons
       (gears.table.join
        (awful.button [] 1 (fn [t] (t:view_only)))
        (awful.button [ modkey ] 1 (fn [t] (if client.focus (client.focus:move_to_tag t))))

        (awful.button [] 3 awful.tag.viewtoggle)
        (awful.button [ modkey ] 3 (fn [t] (if client.focus (client.focus:toggle_tag t))))

        (awful.button [] 4 (fn [t] (awful.tag.viewnext t.screen)))
        (awful.button [] 5 (fn [t] (awful.tag.viewprev t.screen)))
	      ))

(local tasklist_buttons
       (gears.table.join
	 (awful.button [] 1 (fn [c]
				(if (= c client.focus)
				    (set c.minimized true)
				  (c:emit_signal "request::activate"
						 "tasklist"
						 { :raise true }))))
	 (awful.button [] 3 (fn [] (awful.menu.client_list { :theme { :width 250 } })))
	 (awful.button [] 4 (fn [] (awful.client.focus.byidx 1)))
	 (awful.button [] 5 (fn [] (awful.client.focus.byidx -1)))
	 ))

(set menubar.utils.terminal terminal)

(set awful.layout.layouts
     [ awful.layout.suit.tile
       awful.layout.suit.floating
       awful.layout.suit.max
       awful.layout.suit.max.fullscreen ])

(fn set_wallpaper [s]
  (when beautiful.wallpaper
    (var wallpaper beautiful.wallpaper)
    (when (= (type wallpaper) "function")
      (set wallpaper (wallpaper s)))
    (gears.wallpaper.maximized wallpaper s true)))

(screen.connect_signal "property::geometry" set_wallpaper)

(awful.screen.connect_for_each_screen
  (fn [s]
    (set_wallpaper s)
    (awful.tag ["1" "2" "3" "4" "5"] s (. awful.layout.layouts 1))
    (set s.mypromptbox (awful.widget.prompt))
    (set s.mylayoutbox (awful.widget.layoutbox s))
    (s.mylayoutbox:buttons
      (gears.table.join
	(awful.button [] 1 (fn [] (awful.layout.inc 1)))
	(awful.button [] 3 (fn [] (awful.layout.inc -1)))
	(awful.button [] 4 (fn [] (awful.layout.inc 1)))
	(awful.button [] 5 (fn [] (awful.layout.inc -1)))
	))

    (set s.mytaglist (awful.widget.taglist
		       { :screen s
		         :filter awful.widget.taglist.filter.all
			 :buttons taglist_buttons }))
    (set s.mytasklist (awful.widget.tasklist
	 	        { :screen s
	 	          :filter awful.widget.taglist.filter.currenttags
	 	          :buttons tasklist_buttons }))

    (set s.mywibox (awful.wibar { :position "top" :screen s }))

    (s.mywibox:setup
      {
        :layout wibox.layout.align.horizontal
	1 {
	  :layout wibox.layout.fixed.horizontal
	  1 mylauncher
	  2 s.mytaglist
	  3 s.mypromptbox
	}
	2 s.mytasklist
	3 {
	  :layout wibox.layout.fixed.horizontal
	  1 mykeyboardlayout
	  2 (wibox.widget.systray)
	  3 mytextclock
	  4 s.mylayoutbox
	}
      })
    ))

(root.buttons
  (gears.table.join
    (awful.button [] 3 (fn [] (mymainmenu:toggle)))
    (awful.button [] 4 awful.tag.viewnext)
    (awful.button [] 5 awful.tag.viewprev)
    ))

(var globalkeys
 (gears.table.join
  (awful.key [ modkey ] "s" hotkeys_popup.show_help
   { :description "show help" :group "awesome" })
  (awful.key [ modkey ] "j" (fn [] (awful.client.focus.global_bydirection "down"))
   { :description "focus down" :group "client" })
  (awful.key [ modkey ] "k" (fn [] (awful.client.focus.global_bydirection "up"))
   { :description "focus up" :group "client" })
  (awful.key [ modkey ] "h" (fn [] (awful.client.focus.global_bydirection "left"))
   { :description "focus left" :group "client" })
  (awful.key [ modkey ] "l" (fn [] (awful.client.focus.global_bydirection "right"))
   { :description "focus right" :group "client" })

  (awful.key [ modkey ] "Return" (fn [] (awful.spawn terminal))
   { :description "open a terminal" :group "launcher" })

  (awful.key [ modkey "Control" ] "r" awesome.restart
   { :description "reload awesome" :group "awesome" })
  (awful.key [ modkey "Control" "Shift" ] "r"
	     (fn []
		 (let [s (awful.screen.focused)]
		   (s.mypromptbox:run)))
   { :description "run prompt" :group "launcher" })

  (awful.key [ modkey ] "p" (fn [] (menubar.show))
   { :description "show menubar" :group "launcher" })))


(local clientkeys
       (gears.table.join
	 (awful.key [ modkey ] "f"
		    (fn [c]
			(set c.fullscreen (not c.fullscreen))
			(c:raise))
		    { :description "toggle fullscreen" :group "client" })
	 (awful.key [ modkey "Shift" ] "c" (fn [c] (c:kill))
		    { :description "close" :group "client" })
	 (awful.key [ modkey "Control" ] "space" awful.client.floating.toggle
		    { :description "toggle floating" :group "client" })
	 (awful.key [ modkey "Control" ] "Return" (fn [c] (c:swap (awful.client.getmaster)))
		    { :description "move to master" :group "client" })
	 (awful.key [ modkey ] "o" (fn [c] (c:move_to_screen))
		    { :description "move to screen" :group "client" })
	 (awful.key [ modkey ] "t" (fn [c] (set c.ontop (not c.ontop)))
		    { :description "toggle keep on top" :group "client" })

	 ;; The client currently has the input focus, so it cannot be
	 ;; minimized, since minimized clients can't have the focus.
	 (awful.key [ modkey ] "n" (fn [c] (set c.minimized true))
		    { :description "minimize" :group "client" })
	 (awful.key [ modkey ] "m" (fn [c] (set c.maximized (not c.maximized)) (c:raise))
		    { :description "(un)maximize" :group "client" })))

;; Bind all key numbers to tags.
;; Be careful: we use keycodes to make it work on any keyboard layout.
;; This should map on the top row of your keyboard, usually 1 to 9.
(for [i 1 9]
  (set globalkeys (gears.table.join globalkeys
        ;; View tag only.
        (awful.key [ modkey ] (.. "#" (+ i 9))
		   (fn []
		       (let [scr (awful.screen.focused)
			     tag (. scr.tags i)]
			 (if tag (tag:view_only))))
                   { :description (.. "view tag #" i) :group "tag"})
        ;; Toggle tag display.
        (awful.key [ modkey "Control" ] (.. "#" (+ i 9))
                   (fn []
		       (let [scr (awful.screen.focused)
			     tag (. scr.tags i)]
			 (if tag (awful.tag.viewtoggle tag))))
                   { :description (.. "toggle tag #" i) :group "tag"})
        ;; Move client to tag.
        (awful.key [ modkey "Shift" ] (.. "#" (+ i 9))
                   (fn []
		     (when client.focus
		       (let [tag (client.focus.screen.tags i)]
			 (if tag (client.focus:move_to_tag tag)))))
                   { :description (.. "move focused client to tag #" i) :group "tag"})
        ;; Toggle tag on focused client.
        (awful.key [ modkey "Control" "Shift" ] (.. "#" (+ i 9))
                   (fn []
                     (when client.focus
		       (let [tag (client.focus.screen.tags i)]
			 (if tag (client.focus:toggle_tag tag)))))
                   { :description (.. "toggle focused client on tag #" i) :group "tag"}))))

(local clientbuttons
       (gears.table.join
         (awful.button [ ] 1 (fn [c]
             (c:emit_signal "request::activate" "mouse_click" { :raise true })))
         (awful.button [ modkey ] 1 (fn [c]
             (c:emit_signal "request::activate" "mouse_click" { :raise true })
             (awful.mouse.client.move c)))
         (awful.button [ modkey ] 3 (fn [c]
             (c:emit_signal "request::activate" "mouse_click" { :raise true })
             (awful.mouse.client.resize c)))))

;; Set keys
(root.keys globalkeys)

;; Rules
(set awful.rules.rules
     [
      ;; All clients will match this rule.
      {
        :rule []
        :properties {
          :border_width beautiful.border_width
          :border_color beautiful.border_normal
          :focus awful.client.focus.filter
          :raise true
          :keys clientkeys
          :buttons clientbuttons
          :screen awful.screen.preferred
          :placement (+ awful.placement.no_overlap awful.placement.no_offscreen)
        }

	;; Floating clients.
	{
	  :rule_any {
            :instance [
              "DTA"    ; Firefox addon DownThemAll.
	      "copyq"  ; Includes session name in class.
              "pinentry"
            ]
            :class [
              "Arandr"
              "Blueman-manager"
              "Gpick"
              "Kruler"
              "MessageWin"    ; kalarm.
              "Sxiv"
              "Tor Browser"   ; Needs a fixed window size to avoid fingerprinting by screen size.
              "Wpa_gui"
              "veromix"
              "xtightvncviewer"
	    ]

	    ;; Note that the name property shown in xprop might be set slightly
	    ;; after creation of the client and the name shown there might not
	    ;; match defined rules here.
            :name [
              "Event Tester"   ; xev.
            ]
            :role [
              "AlarmWindow"    ; Thunderbird's calendar.
              "ConfigManager"  ; Thunderbird's about:config.
              "pop-up"         ; e.g. Google Chrome's (detached) Developer Tools.
            ]
          }
	  :properties { :floating true }
	}

        ;; Add titlebars to normal clients and dialogs
        {
	  :rule_any { :type [ "normal" "dialog" ] }
	  :properties { :titlebars_enabled true }
	}
      }

      ;; Set Firefox to always map on the tag named "2" on screen 1.
      ;; { rule = { class = "Firefox" },
      ;;   properties = { screen = 1, tag = "2" } },
    ])


;;
;;;
(client.connect_signal
  "manage"
  (fn [c]
    ;; Set the windows at the slave,
    ;; i.e. put it at the end of others instead of setting it master.
    ;; if not awesome.startup then awful.client.setslave(c) end
    (when (and awesome.startup
	       (not c.size_hints.user_position)
	       (not c.size_hints.program_position))
      ;; Prevent clients from being unreachable after screen count changes.
      (awful.placement.no_offscreen c))))

;; Add a titlebar if titlebars_enabled is set to true in the rules.
(client.connect_signal
  "request::titlebars"
  (fn [c]
    ;; buttons for the titlebar
    (local buttons (gears.table.join
        (awful.button [ ] 1 (fn []
            (c:emit_signal "request::activate" "titlebar" { :raise true })
            (awful.mouse.client.move c)))
        (awful.button [ ] 3 (fn []
            (c:emit_signal "request::activate" "titlebar" { :raise true })
            (awful.mouse.client.resize c)))))

    (let [tb (awful.titlebar c)]
      (set tb.widget [
          { ; Left
              1 (awful.titlebar.widget.iconwidget c)
              :buttons buttons
              :layout  wibox.layout.fixed.horizontal
          }
          { ; Middle
              1 { ; Title
                  :align  "center"
                  :widget (awful.titlebar.widget.titlewidget c)
              }
              :buttons buttons
              :layout  wibox.layout.flex.horizontal
          }
          { ; Right
              :layout (wibox.layout.fixed.horizontal)
              1 (awful.titlebar.widget.floatingbutton  c)
              2 (awful.titlebar.widget.maximizedbutton c)
              3 (awful.titlebar.widget.stickybutton    c)
              4 (awful.titlebar.widget.ontopbutton     c)
              5 (awful.titlebar.widget.closebutton     c)
          }
          :layout wibox.layout.align.horizontal
        ]))))

;; ...
(client.connect_signal "focus"   (fn [c] (set c.border_color beautiful.border_focus)))
(client.connect_signal "unfocus" (fn [c] (set c.border_color beautiful.border_normal)))
