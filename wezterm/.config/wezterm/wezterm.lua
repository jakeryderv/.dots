local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("0xProto Nerd Font")
config.color_scheme = "carbonfox"
config.window_decorations = "RESIZE"

config.use_fancy_tab_bar = false
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.tab_max_width = 999
config.show_new_tab_button_in_tab_bar = false

config.colors = {
	tab_bar = {
		background = "#2a2a2a",
		inactive_tab = { bg_color = "#2a2a2a", fg_color = "#6e6f70" },
	},
}

wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
	local title = tab.active_pane.title
	title = wezterm.truncate_right(title, max_width)
	local pad = max_width - #title
	local left = math.floor(pad / 2)
	local right = pad - left
	return string.rep(" ", left) .. title .. string.rep(" ", right)
end)

return config
