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

config.use_fancy_tab_bar = true
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false

config.colors = {
	tab_bar = {
		background = "#2a2a2a",
		inactive_tab = { bg_color = "#2a2a2a", fg_color = "#6e6f70" },
		active_tab = { bg_color = "#78a9ff", fg_color = "#0c0c0c" },
	},
	visual_bell = "#78a9ff",
	split = "#78a9ff",
}

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	fade_in_function = "EaseIn",
	fade_out_function = "EaseOut",
}
config.enable_scroll_bar = true

config.inactive_pane_hsb = {
	hue = 1.0,
	saturation = 0.75,
	brightness = 0.4,
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

	-- Scrolling
	{ key = "b", mods = "CTRL|ALT", action = act.ScrollByPage(-1) },
	{ key = "f", mods = "CTRL|ALT", action = act.ScrollByPage(1) },
	{ key = "u", mods = "CTRL|ALT", action = act.ScrollByPage(-0.5) },
	{ key = "d", mods = "CTRL|ALT", action = act.ScrollByPage(0.5) },
	{ key = "g", mods = "CTRL|ALT", action = act.ScrollToTop },
	{ key = "g", mods = "CTRL|ALT|SHIFT", action = act.ScrollToBottom },
	{ key = "[", mods = "CTRL|ALT", action = act.ScrollToPrompt(-1) },
	{ key = "]", mods = "CTRL|ALT", action = act.ScrollToPrompt(1) },

	-- Search & Selection
	{ key = "/", mods = "CTRL|ALT", action = act.Search({ CaseSensitiveString = "" }) },
	{ key = "v", mods = "CTRL|ALT", action = act.ActivateCopyMode },
	{ key = "Space", mods = "CTRL|ALT", action = act.QuickSelect },
}

-- ============================================
-- Tab bar status (native, right side)
-- ============================================
local battery_icon = wezterm.nerdfonts.fa_battery_full or "BAT"
local clock_icon = wezterm.nerdfonts.fa_clock_o or "TIME"

-- RAM used in GB (from /proc/meminfo)
local function ram_usage()
	local f = io.open("/proc/meminfo", "r")
	if not f then return "?" end
	local total, available
	for line in f:lines() do
		local k, v = line:match("^(%w+):%s+(%d+)")
		if k == "MemTotal" then total = tonumber(v) end
		if k == "MemAvailable" then available = tonumber(v) end
		if total and available then break end
	end
	f:close()
	if total and available then
		return string.format("%.2f GB", (total - available) / 1024 / 1024)
	end
	return "?"
end

-- CPU usage % (delta from /proc/stat, cached 1s)
local cpu_prev = { total = 0, idle = 0 }
local cpu_cache = { value = "0%", time = 0 }
local function cpu_usage()
	local now = os.time()
	if now - cpu_cache.time >= 1 then
		local f = io.open("/proc/stat", "r")
		if f then
			local line = f:read("*l")
			f:close()
			local nums = {}
			for n in line:gmatch("%d+") do
				nums[#nums + 1] = tonumber(n)
			end
			local total = 0
			for _, n in ipairs(nums) do total = total + n end
			local idle = nums[4]
			local total_diff = total - cpu_prev.total
			local idle_diff = idle - cpu_prev.idle
			if cpu_prev.total > 0 and total_diff > 0 then
				cpu_cache.value = string.format("%.1f%%", (1 - idle_diff / total_diff) * 100)
			end
			cpu_prev.total = total
			cpu_prev.idle = idle
		end
		cpu_cache.time = now
	end
	return cpu_cache.value
end

-- GPU usage % (NVIDIA, cached 3s)
local gpu_cache = { value = "--", time = 0 }
local function gpu_usage()
	local now = os.time()
	if now - gpu_cache.time > 3 then
		local handle =
			io.popen("nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null")
		if handle then
			local result = handle:read("*l")
			handle:close()
			if result and result ~= "" then
				gpu_cache.value = result .. "%"
			end
		end
		gpu_cache.time = now
	end
	return gpu_cache.value
end

-- Battery % from /sys
local function battery_pct()
	for _, name in ipairs({ "BAT0", "BAT1" }) do
		local f = io.open("/sys/class/power_supply/" .. name .. "/capacity", "r")
		if f then
			local pct = f:read("*l")
			f:close()
			if pct then return pct .. "%" end
		end
	end
	return "?"
end

wezterm.on("update-status", function(window, pane)
	local right = string.format(
		"[RAM %s] [CPU %s] [GPU %s] [%s %s] [%s %s]",
		ram_usage(), cpu_usage(), gpu_usage(),
		battery_icon, battery_pct(),
		clock_icon, os.date("%Y-%m-%d %H:%M")
	)
	window:set_right_status(wezterm.format({
		{ Background = { Color = "#78a9ff" } },
		{ Foreground = { Color = "#0c0c0c" } },
		{ Attribute = { Intensity = "Bold" } },
		{ Text = " " .. right .. " " },
	}))
end)

return config
