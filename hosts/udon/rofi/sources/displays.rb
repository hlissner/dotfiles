#!/usr/bin/env cached-nix-shell
#! nix-shell ../shell.nix --keep XDG_DATA_DIRS -i ruby
#
# TODO

require_relative '../lib'

Rofi.define :displays do |d|
  icon = 'video-display-symbolic'

  d.on_entries do |source|
    Rofi::Entry.new(source, text: 'Monitor Layout: ', icon: icon) do |_, c|
      # break Rofi.execute(:mount)
      break Sh.coproc('xrandr', '...') # TODO
    end
  end

  d.on_sources do
    s = Rofi::Source.new
    s.text = "Display Settings"
    s.icon = icon

    s.on_accept_entry do |e, c|
    end

    s.on_start do |c|
      data = Sh.call("xrandr")

    end

    [s]
  end
end
