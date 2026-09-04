#!/usr/bin/env bash

hyprctl hyprsunset identity >/dev/null 2>&1 || true
sleep 0.1
hyprctl dispatch 'hl.dsp.exit()'
