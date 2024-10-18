#!/bin/sh

# The wifi_change event supplies a $INFO variable in which the current SSID
# is passed to the script.

# Workaround for Apple stop supplying the SSID after the Sonoma update
# https://github.com/FelixKratz/SketchyBar/issues/407#issuecomment-1755765318
WIFI="$(ipconfig getifaddr en0)" || WIFI="No IP"
sketchybar --set $NAME label="${WIFI}"
#if [ "$SENDER" = "wifi_change" ]; then
#  WIFI=${INFO}
#  sketchybar --set $NAME label="${WIFI}"
#fi

