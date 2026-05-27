local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
	"0xProto Nerd Font Mono",
	"JetBrains Mono",
	"Symbols Nerd Font Mono",
	"Noto Color Emoji",
})
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.font_size = 12.0
config.font_dirs = {}
config.font_shaper = "Harfbuzz"
config.bold_brightens_ansi_colors = true
config.freetype_load_flags = "DEFAULT"
config.freetype_load_target = "Normal"
config.freetype_render_target = "Normal"
config.cell_width = 1.0
config.line_height = 1.0

config.color_scheme = "carbonfox"
config.window_decorations = "RESIZE"
config.window_background_image = "/home/jake/Pictures/wallpapers/dark-space-blur-s5.jpg"
config.window_background_image_hsb = {
	brightness = 0.15,
	saturation = 1.0,
	hue = 1.0,
}
config.window_background_opacity = 1.0

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

config.inactive_pane_hsb = {
	hue = 1.0,
	saturation = 0.9,
	brightness = 0.8,
}

-- ============================================
-- Keybindings
-- ============================================
local act = wezterm.action

config.keys = {
	-- Tabs
	{ key = "t", mods = "CTRL|ALT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CTRL|ALT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "n", mods = "CTRL|ALT", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "CTRL|ALT", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "CTRL|ALT|SHIFT", action = act.MoveTabRelative(1) },
	{ key = "p", mods = "CTRL|ALT|SHIFT", action = act.MoveTabRelative(-1) },
	{ key = "1", mods = "CTRL|ALT", action = act.ActivateTab(0) },
	{ key = "2", mods = "CTRL|ALT", action = act.ActivateTab(1) },
	{ key = "3", mods = "CTRL|ALT", action = act.ActivateTab(2) },
	{ key = "4", mods = "CTRL|ALT", action = act.ActivateTab(3) },
	{ key = "5", mods = "CTRL|ALT", action = act.ActivateTab(4) },
	{ key = "6", mods = "CTRL|ALT", action = act.ActivateTab(5) },
	{ key = "7", mods = "CTRL|ALT", action = act.ActivateTab(6) },
	{ key = "8", mods = "CTRL|ALT", action = act.ActivateTab(7) },
	{ key = "9", mods = "CTRL|ALT", action = act.ActivateTab(8) },

	-- Windows
	{ key = "w", mods = "CTRL|ALT|SHIFT", action = act.SpawnWindow },

	-- Panes / Splits
	{ key = "\\", mods = "CTRL|ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "CTRL|ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "x", mods = "CTRL|ALT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "CTRL|ALT", action = act.TogglePaneZoomState },
	{ key = "h", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL|ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "h", mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "CTRL|ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
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
