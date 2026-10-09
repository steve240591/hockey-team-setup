#!/bin/sh
# Java-Trainer im Browser starten (ohne Mac-App): im Terminal  ./starten.sh
# Die Mac-App baust du mit  ./mac/app-bauen.sh
cd "$(dirname "$0")" || exit 1
if ! command -v java >/dev/null 2>&1; then
    echo "Java wurde nicht gefunden. Bitte ein JDK ab Version 17 installieren."
    exit 1
fi
if ! ./werkzeuge/sdk-laden.sh; then
    echo "Das Anthropic-SDK konnte nicht geladen werden. Bist du online?"
    exit 1
fi
exec java -cp "lib/*" Trainer.java
