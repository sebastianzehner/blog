#!/bin/bash

echo "Title 1:"
read TITLE1
echo "Title 2:"
read TITLE2

# Automatische Dateinamen-Generierung
AUTO_FILENAME=$(echo "${TITLE1}-${TITLE2}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-cover.webp

echo "Output filename (default: ${AUTO_FILENAME}):"
read OUTPUT
OUTPUT="${OUTPUT:-$AUTO_FILENAME}"

# Catppuccin Mocha Colors
BG_COLOR='#45475a'      # Surface1
TEXT1_COLOR='#89b4fa'   # Blue
TEXT2_COLOR='#fab387'   # Peach

magick -size 1280x720 xc:"$BG_COLOR" \
  -font "/usr/share/fonts/TTF/CaskaydiaCoveNerdFontMono-Regular.ttf" \
  -pointsize 120 -fill "$TEXT1_COLOR" \
  -gravity center -annotate +0-80 "$TITLE1" \
  -pointsize 120 -fill "$TEXT2_COLOR" \
  -gravity center -annotate +0+50 "$TITLE2" \
  "$OUTPUT"

echo "✓ Created: $OUTPUT"
