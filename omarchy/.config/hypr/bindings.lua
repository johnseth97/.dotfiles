-- Omarchy Defaults
require("hypr.bindings.media")
require("hypr.bindings.clipboard")
require("hypr.bindings.tiling")
require("hypr.bindings.utilities")
require("hypr.bindings.voxtype")
require("hypr.bindings.applications")


-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Was bound to a Google Maps webapp by default (bindings/applications.lua);
-- repurposed for screenshot instead.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- Was bound to Spotify by default (bindings/applications.lua); repurposed
-- for Cider. "cider" isn't in omarchy's curated app registry (only a few
-- apps like spotify/signal/1password get the { omarchy = "..." } shortcut).
-- omarchy-launch-or-focus matches window class OR title, which picked up
-- any browser tab mentioning "cider" -- scripts/focus-or-launch-cider.sh
-- matches on window class only instead.
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", "~/.config/hypr/scripts/focus-or-launch-cider.sh")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- HJKL -> JKL;

-- caps -> ctrl
-- o.bind("CAPS", "ctrl")

-- Was "Toggle top bar" in bindings/utilities.lua. Match the 1Password Quick
-- Access shortcut used on macOS; Wayland needs the compositor to bind it.
o.rebind("SUPER + SHIFT + SPACE", "1Password Quick Access", {
  launch = "1password --force-device-scale-factor=1 --quick-access",
})
