-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end
if get_appearance():find("Dark") then
  config.color_scheme = "Tokyo Night Moon"
else
  config.color_scheme = "Tokyo Night Day"
end

config.check_for_updates = true
config.enable_tab_bar = false
config.font_size = 16
config.font = wezterm.font_with_fallback({
  "Menlo",
  "Hack Nerd Font Mono",
})
config.keys = {
  -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
  { key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
  -- Make Option-Right equivalent to Alt-f; forward-word
  { key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },
  -- Disable default key binding for opening a new tab
  { key = "t", mods = "SUPER", action = wezterm.action.DisableDefaultAssignment },
  -- Ensure confirmation when closing window using keyboard shortcut
  {
    key = "w",
    mods = "CMD",
    action = wezterm.action.CloseCurrentTab({ confirm = true }),
  },
}
config.window_decorations = "RESIZE" -- See also "INTEGRATED_BUTTONS|RESIZE"

-- Start WezTerm maximized
wezterm.on("gui-startup", function()
  local _tab, _pane, window = wezterm.mux.spawn_window({})
  window:gui_window():maximize()
end)

-- and finally, return the configuration to wezterm
return config
