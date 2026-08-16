#!/usr/bin/env bash

DEFAULT_NAME="Screenshot_Area_$(date +%Y%m%d_%H%M%S).png"
TEMP_FILE="/tmp/$DEFAULT_NAME"

if grim -g "$(slurp)" "$TEMP_FILE"; then

    FILE_PATH="$(zenity --file-selection --save --confirm-overwrite --filename="$HOME/Képek/$DEFAULT_NAME" --title="Kijelölt terület mentése mint...")"

    if [[ -n "$FILE_PATH" ]]; then
        mv "$TEMP_FILE" "$FILE_PATH"
    else
        rm -f "$TEMP_FILE"
    fi
else
    rm -f "$TEMP_FILE"
fi
