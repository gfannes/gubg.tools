local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.default_prog = { '/bin/bash', '--init-file', '/home/geertf/gubg/bin/all-bash.sh' }

config.font_size = 11.0
config.color_scheme = 'Afterglow'

config.hide_mouse_cursor_when_typing = false

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
  { key = '1', mods = 'CTRL', action = act.MoveTab(1-1), },
  { key = '2', mods = 'CTRL', action = act.MoveTab(2-1), },
  { key = '3', mods = 'CTRL', action = act.MoveTab(3-1), },
  { key = '4', mods = 'CTRL', action = act.MoveTab(4-1), },
  { key = '5', mods = 'CTRL', action = act.MoveTab(5-1), },
  { key = '6', mods = 'CTRL', action = act.MoveTab(6-1), },
  { key = '7', mods = 'CTRL', action = act.MoveTab(7-1), },
  { key = '8', mods = 'CTRL', action = act.MoveTab(8-1), },
  { key = '9', mods = 'CTRL', action = act.MoveTab(9-1), },
  { key = '0', mods = 'CTRL', action = act.MoveTab(10-1), },

  { key = 'Enter', mods = 'ALT', action = act.DisableDefaultAssignment,},
}

return config
