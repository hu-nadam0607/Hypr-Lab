#!/usr/bin/env bash

DEFAULT_NAME="Screenshot_Area_$(date +%Y%m%d_%H%M%S).png"
TEMP_FILE="/tmp/$DEFAULT_NAME"

# 1. ELŐSZÖR kijelöljük a területet és lefotózzuk
if grim -g "$(slurp)" "$TEMP_FILE"; then
    
    # 2. CSAK HA a fotó sikeresen elkészült, UTÁNA kérdezzük meg a mentés helyét
    FILE_PATH=$(zenity --file-selection --save --confirm-overwrite --filename="$HOME/Képek/$DEFAULT_NAME" --title="Kijelölt terület mentése mint...")
    
    # 3. Véglegesítés vagy takarítás
    if [ -n "$FILE_PATH" ]; then
        mv "$TEMP_FILE" "$FILE_PATH"
    else
        rm -f "$TEMP_FILE"
    fi
else
    # Ha még a kijelölés közben meggondolod magad és nyomsz egy ESC-et, ne csináljon semmit
    rm -f "$TEMP_FILE"
fi
