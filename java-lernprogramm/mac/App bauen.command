#!/bin/sh
# Doppelklick im Finder: baut die Java-Trainer-App und legt sie in "Programme".
# Die komplette Ausgabe landet zusätzlich in mac/bauprotokoll.txt.
cd "$(dirname "$0")/.." || exit 1
sh mac/app-bauen.sh 2>&1 | tee mac/bauprotokoll.txt
echo ""
echo "Du kannst dieses Fenster jetzt schließen."
