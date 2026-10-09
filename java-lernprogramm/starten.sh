#!/bin/sh
# Java-Trainer starten (macOS/Linux): im Terminal  ./starten.sh
cd "$(dirname "$0")" || exit 1
if ! command -v java >/dev/null 2>&1; then
    echo "Java wurde nicht gefunden. Bitte ein JDK ab Version 17 installieren."
    exit 1
fi
exec java Trainer.java
