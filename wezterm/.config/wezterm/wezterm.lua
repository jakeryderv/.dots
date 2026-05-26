local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font '0xProto Nerd Font'
config.color_scheme = 'carbonfox'

return config
