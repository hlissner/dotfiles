-- config/hypr/lib/match.lua
--
-- hl.window_rule's `match` table, reimplemented against an HL.Window: Hyprland
-- won't lend out its rule engine, and matches a gesture on fingers, mods and
-- direction and nothing else.

local M = {}

local function negated(want)
  if want:sub(1, 9) == "negative:" then return want:sub(10), true end
  return want, false
end

-- Hyprland matches with RE2 in *full match* mode. Lua patterns aren't RE2, and
-- what RE2 has that they don't doesn't fail here -- it quietly matches nothing
-- -- so it's a declaration error instead. Anchors come off before going back
-- on: ^librewolf$ is how I spell these, and a $ that isn't last is a literal.
local function regex(want)
  local pat, negate = negated(want)
  if pat:find("[\\|{]") or pat:find("%)[*+?]") then
    error(("match pattern %q uses RE2 syntax Lua patterns don't have"):format(want), 0)
  end
  pat = "^" .. (pat:gsub("^%^", ""):gsub("([^%%])%$$", "%1")) .. "$"
  return function(v)
    if type(v) ~= "string" then return negate end
    return (v:match(pat) ~= nil) ~= negate
  end
end

local TRUTHY = { ["true"] = true, yes = true, on = true, ["1"] = true }

local function boolean(want)
  if type(want) == "string" then want = TRUTHY[want:lower()] end
  want = want and true or false
  return function(v) return (v and true or false) == want end
end

local function integer(want)
  want = tonumber(want)
  return function(v) return tonumber(v) == want end
end

-- A dynamic tag is stored with a trailing *; the lookup takes either spelling.
local function tag(want)
  local name, negate = negated(want)
  return function(tags)
    for _, t in ipairs(tags or {}) do
      if t == name or t == name .. "*" then return not negate end
    end
    return negate
  end
end

-- Hyprland's workspace selectors are a grammar (r[1-5], w[t1-3], m[+1]...) and
-- not worth reimplementing, so the unambiguous spellings work and anything else
-- is a declaration error -- better than a rule that silently never fires.
local function workspace(want)
  if type(want) == "string" and want:find("[%[%]]") then
    error(("workspace selector %q isn't reimplemented here; use an id, a name, or \"special\""):format(want), 0)
  end
  return function(ws)
    if not ws then return false end
    if type(want) == "number" then return ws.id == want end
    if want == "special" then return ws.special == true end
    return ws.name == (want:gsub("^name:", ""))
  end
end

-- A layout name, or a list of them. Deliberately not a regex: what you want
-- here is "scrolling or master", and Lua patterns have no alternation.
local function layout(want)
  local set = {}
  for _, v in ipairs(type(want) == "table" and want or { want }) do set[v] = true end
  return function(l) return l ~= nil and set[l] == true end
end

-- What hl.window_rule takes that a window object can answer. Left out on
-- purpose: `modal` and `namespace` (nothing on HL.Window holds them), and
-- exec_token/exec_pid (they only mean anything while a window is opening).
local PROPS = {
  class          = { regex,   function(w) return w.class end },
  title          = { regex,   function(w) return w.title end },
  initial_class  = { regex,   function(w) return w.initial_class end },
  initial_title  = { regex,   function(w) return w.initial_title end },
  content        = { regex,   function(w) return w.content_type end },
  xdg_tag        = { regex,   function(w) return w.xdg_tag end },
  float          = { boolean, function(w) return w.floating end },
  xwayland       = { boolean, function(w) return w.xwayland end },
  pin            = { boolean, function(w) return w.pinned end },
  focus          = { boolean, function(w) return w.active end },
  group          = { boolean, function(w) return w.group ~= nil end },
  fullscreen     = { boolean, function(w) return w.fullscreen ~= 0 end },
  tag            = { tag,     function(w) return w.tags end },
  workspace      = { workspace, function(w) return w.workspace end },
  fullscreen_state_internal = { integer, function(w) return w.fullscreen end },
  fullscreen_state_client   = { integer, function(w) return w.fullscreen_client end },
}

local function known()
  local names = { "layout" }
  for k in pairs(PROPS) do names[#names + 1] = k end
  table.sort(names)
  return table.concat(names, ", ")
end

-- Compile SPEC (a match table) once, at declaration, so a typo is a config
-- error instead of a gesture that never fires. `action` is skipped: a matcher
-- is spelled as its conditions plus what to do about them.
function M.compile(spec)
  local tests = {}
  for key, want in pairs(spec or {}) do
    if key == "layout" then
      local test = layout(want)
      tests[#tests + 1] = function(_, l) return test(l) end
    elseif key ~= "action" then
      local prop = PROPS[key] or
        error(("unknown match property %q (have: %s)"):format(key, known()), 0)
      local test, get = prop[1](want), prop[2]
      -- Asking about a window you don't have is a miss; a layout-only rule
      -- never asks.
      tests[#tests + 1] = function(w) return w ~= nil and test(get(w)) end
    end
  end
  return tests
end

function M.ok(tests, win, layout)
  for _, test in ipairs(tests) do
    if not test(win, layout) then return false end
  end
  return true
end

return M
