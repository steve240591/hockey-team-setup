#!/bin/sh
# Doppelklick im Finder: baut die Java-Trainer-App und legt sie in "Programme".
cd "$(dirname "$0")/.." || exit 1
sh mac/app-bauen.sh
echo ""
echo "Du kannst dieses Fenster jetzt schließen."
