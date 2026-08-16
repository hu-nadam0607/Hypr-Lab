#!/usr/bin/env bash

DEFAULT_NAME="Screenshot_$(date +%Y%m%d_%H%M%S).png"
TEMP_FILE="/tmp/$DEFAULT_NAME"

grim "$TEMP_FILE"

FILE_PATH="$(zenity --file-selection --save --confirm-overwrite --filename="$HOME/Képek/$DEFAULT_NAME" --title="Képernyőkép mentése mint...")"

if [[ -n "$FILE_PATH" ]]; then
    mv "$TEMP_FILE" "$FILE_PATH"
else
    rm -f "$TEMP_FILE"
fi
