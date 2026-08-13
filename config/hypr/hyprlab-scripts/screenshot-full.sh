#!/usr/bin/env bash

# Alapértelmezett név és egy ideiglenes mentési útvonal a RAM-ban
DEFAULT_NAME="Screenshot_$(date +%Y%m%d_%H%M%S).png"
TEMP_FILE="/tmp/$DEFAULT_NAME"

# 1. AZONNAL elkészítjük a képet a háttérben, így tiszta lesz a képernyő
grim "$TEMP_FILE"

# 2. CSAK EZUTÁN nyitjuk meg a mentési ablakot
FILE_PATH=$(zenity --file-selection --save --confirm-overwrite --filename="$HOME/Képek/$DEFAULT_NAME" --title="Képernyőkép mentése mint...")

# 3. Ha a felhasználó kiválasztotta a helyet, átmozgatjuk az ideiglenes képet
if [ -n "$FILE_PATH" ]; then
    mv "$TEMP_FILE" "$FILE_PATH"
else
    # Ha mégse gombot nyomtál, töröljük a felesleges ideiglenes fájlt
    rm -f "$TEMP_FILE"
fi
