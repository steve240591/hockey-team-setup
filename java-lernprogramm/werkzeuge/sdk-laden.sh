#!/bin/sh
# Lädt das Anthropic-Java-SDK (für den Claude-Coach) einmalig nach java-lernprogramm/lib
# und prüft jede Datei mit ihrer SHA-256-Prüfsumme aus abhaengigkeiten.txt.
set -e
cd "$(dirname "$0")/.."
mkdir -p lib

pruefsumme() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | cut -d' ' -f1
    else
        sha256sum "$1" | cut -d' ' -f1
    fi
}

grep -v '^#' werkzeuge/abhaengigkeiten.txt | while read -r datei soll url; do
    [ -z "$datei" ] && continue
    if [ -f "lib/$datei" ] && [ "$(pruefsumme "lib/$datei")" = "$soll" ]; then
        continue
    fi
    echo "Lade $datei ..."
    curl -fsSL --retry 6 --retry-delay 3 -o "lib/$datei.tmp" "$url"
    ist=$(pruefsumme "lib/$datei.tmp")
    if [ "$ist" != "$soll" ]; then
        rm -f "lib/$datei.tmp"
        echo "FEHLER: Prüfsumme von $datei stimmt nicht. Abbruch." >&2
        exit 1
    fi
    mv "lib/$datei.tmp" "lib/$datei"
done
