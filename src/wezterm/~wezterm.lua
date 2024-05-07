local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.color_scheme = 'Afterglow'

local act = wezterm.action
config.keys = {
  { key = '1', mods = 'ALT', action = act.ActivateTab(1-1), },
  { key = '2', mods = 'ALT', action = act.ActivateTab(2-1), },
  { key = '3', mods = 'ALT', action = act.ActivateTab(3-1), },
  { key = '4', mods = 'ALT', action = act.ActivateTab(4-1), },
  { key = '5', mods = 'ALT', action = act.ActivateTab(5-1), },
  { key = '6', mods = 'ALT', action = act.ActivateTab(6-1), },
  { key = '7', mods = 'ALT', action = act.ActivateTab(7-1), },
  { key = '8', mods = 'ALT', action = act.ActivateTab(8-1), },
  { key = '9', mods = 'ALT', action = act.ActivateTab(9-1), },
  { key = '0', mods = 'ALT', action = act.ActivateTab(10-1), },
}

return config
