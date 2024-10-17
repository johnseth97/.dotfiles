-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- Fonts and rendering
config.front_end = "WebGpu"
config.font = LilexNerdFontMono
config.font_size = 12.5

-- Window setup
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true

-- Color schemes
config.color_scheme = "tokyonight_night"
config.window_background_opacity = 1.0

-- and finally, return the configuration to wezterm
return config
