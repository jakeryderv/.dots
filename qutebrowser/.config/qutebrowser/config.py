# ################################################################################
#                               MY CONFIG
# ################################################################################

# pyright: reportUndefinedVariable=false
# ruff: noqa: F821
# (c and config are injected by qutebrowser at runtime)

config.load_autoconfig(False)

# ============================================================
# general stuff
# ============================================================

c.hints.chars = "1234567890"

c.zoom.default = "100%"

c.scrolling.smooth = True


c.fonts.default_family = "0xProto Nerd Font Mono"
c.fonts.default_size = "12pt"


c.window.hide_decoration = True


c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.algorithm = "lightness-cielab"
c.colors.webpage.darkmode.policy.images = "never"
c.colors.webpage.darkmode.policy.page = "smart"
c.colors.webpage.preferred_color_scheme = "dark"


c.tabs.position = "top"
c.tabs.show = "multiple"
c.tabs.pinned.frozen = True
c.tabs.title.format = "{audio}{current_title}"
c.tabs.indicator.width = 4
c.tabs.indicator.padding = {"top": 0, "bottom": 0, "left": 0, "right": 5}


c.statusbar.show = "in-mode"


c.completion.height = "30%"
c.completion.shrink = False
c.completion.scrollbar.width = 8

# ============================================================
# keybinds
# ============================================================

config.bind(",r", "config-source")  # reload config

config.bind("<Ctrl-Shift-P>", "tab-pin;; tab-move 1")  # pin tab & move to position 1

config.bind("<Ctrl-Shift-J>", "tab-move +")
config.bind("<Ctrl-Shift-K>", "tab-move -")


# ============================================================
# CARBONFOX COLORSCHEME
# ============================================================

# Palette
bg = "#161616"  # main background
bg_alt = "#252525"  # alternate background (menus, dialogs)
bg_sel = "#353535"  # selected/highlighted background
fg = "#f2f4f8"  # main text
fg_dim = "#b6b8bb"  # dimmed/inactive text
red = "#ee5396"  # errors, urgent
green = "#25be6a"  # success, insert mode
yellow = "#08bdba"  # warnings (teal in carbonfox)
blue = "#78a9ff"  # links, selections
magenta = "#be95ff"  # caret mode, accents
cyan = "#33b1ff"  # highlights, active elements
pink = "#ff7eb6"  # warnings alt (pink in carbonfox)

# ============================================================
# MAIN UI (always visible)
# ============================================================

# Tabs - bar
c.colors.tabs.bar.bg = bg  # background behind all tabs

# Tabs - unselected
c.colors.tabs.odd.bg = bg
c.colors.tabs.odd.fg = fg_dim
c.colors.tabs.even.bg = bg
c.colors.tabs.even.fg = fg_dim

# Tabs - selected
c.colors.tabs.selected.odd.bg = bg_sel
c.colors.tabs.selected.odd.fg = cyan
c.colors.tabs.selected.even.bg = bg_sel
c.colors.tabs.selected.even.fg = cyan

# Tabs - pinned unselected
c.colors.tabs.pinned.odd.bg = bg
c.colors.tabs.pinned.odd.fg = green
c.colors.tabs.pinned.even.bg = bg
c.colors.tabs.pinned.even.fg = green

# Tabs - pinned selected
c.colors.tabs.pinned.selected.odd.bg = bg_sel
c.colors.tabs.pinned.selected.odd.fg = cyan
c.colors.tabs.pinned.selected.even.bg = bg_sel
c.colors.tabs.pinned.selected.even.fg = cyan

# Tabs - loading indicator
c.colors.tabs.indicator.start = red  # color at start of page load
c.colors.tabs.indicator.stop = cyan  # color when load complete
c.colors.tabs.indicator.error = red  # color on load failure

# Statusbar - normal mode
c.colors.statusbar.normal.bg = bg
c.colors.statusbar.normal.fg = fg

# Statusbar - insert mode (typing in forms)
c.colors.statusbar.insert.bg = green
c.colors.statusbar.insert.fg = bg

# Statusbar - command mode (: commands)
c.colors.statusbar.command.bg = bg
c.colors.statusbar.command.fg = fg

# Statusbar - caret mode (text selection)
c.colors.statusbar.caret.bg = magenta
c.colors.statusbar.caret.fg = bg
c.colors.statusbar.caret.selection.bg = magenta
c.colors.statusbar.caret.selection.fg = bg

# Statusbar - passthrough mode (keys sent to page)
c.colors.statusbar.passthrough.bg = blue
c.colors.statusbar.passthrough.fg = bg

# Statusbar - private browsing
c.colors.statusbar.private.bg = cyan
c.colors.statusbar.private.fg = bg
c.colors.statusbar.command.private.bg = cyan
c.colors.statusbar.command.private.fg = bg

# Statusbar - URL display
c.colors.statusbar.url.fg = fg  # default URL color
c.colors.statusbar.url.hover.fg = cyan  # hovering over link
c.colors.statusbar.url.success.http.fg = fg
c.colors.statusbar.url.success.https.fg = green  # secure connection
c.colors.statusbar.url.warn.fg = yellow  # certificate warning
c.colors.statusbar.url.error.fg = red  # load error
c.colors.statusbar.progress.bg = blue  # page load progress bar

# ============================================================
# INTERACTION (triggered by user)
# ============================================================

# Hints - link labels when pressing f
c.colors.hints.bg = cyan  # hint box background
c.colors.hints.fg = bg  # hint text
c.colors.hints.match.fg = red  # typed characters
c.hints.border = f"2px solid {red}"

# Completion - dropdown for : and o commands
c.colors.completion.fg = fg  # text color
c.colors.completion.odd.bg = bg  # odd row background
c.colors.completion.even.bg = bg_alt  # even row background
c.colors.completion.category.bg = bg_sel  # category header background
c.colors.completion.category.fg = cyan  # category header text
c.colors.completion.category.border.top = bg_sel
c.colors.completion.category.border.bottom = bg_sel
c.colors.completion.item.selected.bg = blue  # selected item background
c.colors.completion.item.selected.fg = bg  # selected item text
c.colors.completion.item.selected.border.top = blue
c.colors.completion.item.selected.border.bottom = blue
c.colors.completion.item.selected.match.fg = red  # matched chars in selection
c.colors.completion.match.fg = magenta  # matched chars (unselected)
c.colors.completion.scrollbar.bg = bg
c.colors.completion.scrollbar.fg = fg_dim

# Keyhint - popup showing available keybinds
c.colors.keyhint.bg = "rgba(22, 22, 22, 0.9)"
c.colors.keyhint.fg = fg
c.colors.keyhint.suffix.fg = yellow  # remaining keys to complete bind

# ============================================================
# POPUPS & DIALOGS
# ============================================================

# Prompts - download dialogs, permission requests
c.colors.prompts.bg = bg_alt
c.colors.prompts.fg = fg
c.colors.prompts.border = f"1px solid {bg_sel}"
c.colors.prompts.selected.bg = blue
c.colors.prompts.selected.fg = bg

# Context menu - right-click menu
c.colors.contextmenu.menu.bg = bg_alt
c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = blue
c.colors.contextmenu.selected.fg = bg
c.colors.contextmenu.disabled.bg = bg_alt
c.colors.contextmenu.disabled.fg = fg_dim

# Messages - info/warning/error bars
c.colors.messages.info.bg = bg
c.colors.messages.info.fg = fg
c.colors.messages.info.border = bg_sel
c.colors.messages.warning.bg = pink
c.colors.messages.warning.fg = bg
c.colors.messages.warning.border = pink
c.colors.messages.error.bg = red
c.colors.messages.error.fg = bg
c.colors.messages.error.border = red

# Downloads bar - bottom bar showing downloads
c.colors.downloads.bar.bg = bg
c.colors.downloads.start.bg = blue  # downloading
c.colors.downloads.start.fg = bg
c.colors.downloads.stop.bg = green  # complete
c.colors.downloads.stop.fg = bg
c.colors.downloads.error.bg = red  # failed
c.colors.downloads.error.fg = bg

# ============================================================
# WEBPAGE
# ============================================================

c.colors.webpage.bg = bg  # background before page loads
