#!/bin/bash

VPN=$(mullvad status | grep Connected ))

if [[ $VPN = "*Connected*"  ]]; then
  sketchybar -m --set $NAME icon= \
                          label="${VPN}" \
                          drawing=on
else
  sketchybar --set $NAME label="${VPN}"
fi
