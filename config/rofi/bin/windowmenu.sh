#!/usr/bin/env dash

rofi \
  -markup \
  -show window \
  -modes window \
  -theme windowmenu \
  -theme-str "configuration{window-format: \"{c}\n{t}\";}"
