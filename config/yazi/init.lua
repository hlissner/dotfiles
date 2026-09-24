-- config/yazi/init.lua --- loaded once at startup, before anything is drawn.

-- Allow yanking between instances of yazi
require("session"):setup { sync_yanked = true }

-- "Which of these to files is the one I just wrote?"
Status:children_add(function(self)
  local h = self._current.hovered
  local time = h and math.floor(h.cha.mtime or 0) or 0
  if time == 0 then
    return ""
  end

  local fmt = os.date("%Y", time) == os.date("%Y") and "%m/%d %H:%M" or "%m/%d  %Y"
  return ui.Line {
    ui.Span(os.date(fmt, time)):style(th.status.perm_sep),
    ui.Span(" "),
  }
end, 500, Status.RIGHT)
