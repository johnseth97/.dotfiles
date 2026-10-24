#!/bin/bash
# Focus the Cider window if one's open, otherwise launch it. Unlike
# omarchy-launch-or-focus, this matches on window CLASS only (exact,
# case-insensitive) -- that helper also matches window TITLE, which picks up
# any browser tab that happens to mention "cider" (e.g. its download page).
# Cider's real WM class is lowercase "cider" at runtime, despite its
# .desktop file claiming StartupWMClass=Cider.

address=$(hyprctl clients -j | jq -r '.[] | select(.class | test("^cider$"; "i")) | .address' | head -n1)

if [[ -n $address ]]; then
  # Matches omarchy-launch-or-focus's own fallback chain: this build of
  # Hyprland routes `dispatch` through a Lua evaluator, so the classic
  # `focuswindow address:X` string needs the hl.dsp.focus(...) form first.
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null 2>&1 \
    || hyprctl dispatch focuswindow "address:$address"
else
  setsid cider >/dev/null 2>&1 &
fi
