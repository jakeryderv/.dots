local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("0xProto Nerd Font")
config.color_scheme = "carbonfox"
config.window_decorations = "RESIZE"

config.use_fancy_tab_bar = true
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.tab_max_width = 16

return config
