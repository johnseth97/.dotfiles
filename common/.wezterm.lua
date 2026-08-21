-- Pull in the wezterm API

-- Pull in the wezterm API
local wezterm = require("wezterm")

return {
	-- Fonts and rendering
	--
	-- Sometimes needed on macos if using nix
	-- front_end = "WebGpu",
	--
	-- Font and size, obviously
	--
	font = wezterm.font_with_fallback({
		"Lilex Nerd Font Mono",
		weight = "Regular",
		stretch = "Normal",
	}),
	font_size = 13,

	-- Window setup
	--
	--Remove top bar
	window_decorations = "RESIZE",
	--Remove tab bar unless tabs are present
	hide_tab_bar_if_only_one_tab = true,

	-- Color schemes and transparency
	--
	color_scheme = "BlulocoDark",
	--
	--Optional transparency
	window_background_opacity = 1.0,
}
