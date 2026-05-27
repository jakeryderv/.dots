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
		background = "#161616",
		inactive_tab = { bg_color = "#161616", fg_color = "#6e6f70" },
		active_tab = { bg_color = "#2a2a2a", fg_color = "#f2f4f8" },
	},
	visual_bell = "#78a9ff",
	split = "#2a2a2a",
}

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.audible_bell = "Disabled"
-- Visual bell handled manually in update-status (icon in top-right corner)
config.enable_scroll_bar = true
config.status_update_interval = 500

config.window_frame = {
	active_titlebar_bg = "#161616",
	inactive_titlebar_bg = "#161616",
}

config.force_reverse_video_cursor = true

-- Slow down mouse wheel scrolling
config.alternate_buffer_wheel_scroll_speed = 1
config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByLine(-2),
	},
	{
		event = { Down = { streak = 1, button = { WheelDown = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByLine(2),
	},
}

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
local ram_icon = wezterm.nerdfonts.md_memory or wezterm.nerdfonts.fa_database or "M"
local cpu_icon = wezterm.nerdfonts.fa_microchip or "C"
local gpu_icon = wezterm.nerdfonts.md_gpu or wezterm.nerdfonts.fa_television or "G"
local bell_icon = wezterm.nerdfonts.fa_bell or wezterm.nerdfonts.md_bell or "BELL"

-- Track bell timestamps per window for the top-right flash indicator
local bell_times = {}
wezterm.on("bell", function(window, pane)
	bell_times[tostring(window:window_id())] = os.time()
end)

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
	if total and available and total > 0 then
		return string.format("%.1f%%", ((total - available) / total) * 100)
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

-- Mode -> color (carbonfox palette)
local mode_colors = {
	NORMAL = "#f2f4f8",       -- white
	COPY_MODE = "#25be6a",    -- green
	SEARCH_MODE = "#08bdba",  -- teal
}

-- Mode -> single-char label
local mode_labels = {
	NORMAL = "N",
	COPY_MODE = "C",
	SEARCH_MODE = "S",
}

-- Tab title: "<cwd-basename>: <process>"
local function basename(path)
	if not path or path == "" then return "" end
	return path:match("([^/\\]+)/?$") or path
end

wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
	local pane = tab.active_pane
	local process = basename(pane.foreground_process_name) or "shell"

	local cwd = "?"
	local raw_cwd = pane.current_working_dir
	if raw_cwd then
		if type(raw_cwd) == "string" then
			cwd = basename((raw_cwd:gsub("^file://[^/]*", "")))
		elseif raw_cwd.file_path then
			cwd = basename(raw_cwd.file_path)
		end
	end

	local fg = tab.is_active and "#f2f4f8" or "#6e6f70"
	return wezterm.format({
		{ Foreground = { Color = "#535353" } },
		{ Text = " [" .. (tab.tab_index + 1) .. "] " },
		{ Foreground = { Color = fg } },
		{ Text = cwd .. ": " .. process .. " " },
	})
end)

wezterm.on("update-status", function(window, pane)
	-- Left: mode indicator (color shifts) + system metrics (color-coded)
	local mode = (window:active_key_table() or "NORMAL"):upper()
	local mode_color = mode_colors[mode] or "#ee5396"
	local mode_label = mode_labels[mode] or "?"
	window:set_left_status(wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		-- Mode (shifting color)
		{ Foreground = { Color = mode_color } },
		{ Text = " [" .. mode_label .. "] " },
		-- Separator
		{ Foreground = { Color = "#535353" } },
		{ Text = "| " },
		-- RAM (blue)
		{ Foreground = { Color = "#78a9ff" } },
		{ Text = ram_icon .. " " .. ram_usage() .. "  " },
		-- CPU (orange)
		{ Foreground = { Color = "#f9a826" } },
		{ Text = cpu_icon .. " " .. cpu_usage() .. "  " },
		-- GPU (green)
		{ Foreground = { Color = "#25be6a" } },
		{ Text = gpu_icon .. " " .. gpu_usage() .. " " },
		-- Separator before tabs
		{ Foreground = { Color = "#535353" } },
		{ Text = "| " },
	}))

	-- Right: bell indicator (3s pulse after bell event), otherwise empty
	local last_bell = bell_times[tostring(window:window_id())]
	if last_bell and (os.time() - last_bell < 3) then
		window:set_right_status(wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = "#ee5396" } },
			{ Text = " " .. bell_icon .. " " },
		}))
	else
		window:set_right_status("")
	end
end)

return config
