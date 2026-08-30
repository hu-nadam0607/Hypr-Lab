#!/usr/bin/env bash

pkill -x quickshell 2>/dev/null || true

sleep 0.5

nohup quickshell >/dev/null 2>&1 &
