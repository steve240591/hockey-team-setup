#!/bin/sh
# Baut die macOS-App "Java-Trainer" und installiert sie im Ordner "Programme".
#
# Aufruf im Terminal (im Ordner java-lernprogramm):
#     ./mac/app-bauen.sh
#
# Voraussetzungen: macOS 13 oder neuer, Xcode oder die Command Line Tools
# (xcode-select --install) und ein JDK ab Version 17.
# Nach Änderungen an den Lektionen einfach erneut ausführen.
set -e
cd "$(dirname "$0")/.."
WURZEL=$(pwd)

# 1. Voraussetzungen prüfen
if [ "$(uname)" != "Darwin" ]; then
    echo "Dieses Skript läuft nur auf macOS." >&2
    exit 1
fi
if ! xcrun --find swiftc >/dev/null 2>&1; then
    echo "Swift-Compiler nicht gefunden. Bitte Xcode installieren oder im Terminal ausführen: xcode-select --install" >&2
    exit 1
fi
if ! JAVA_HOME_PFAD=$(/usr/libexec/java_home -v 17+ 2>/dev/null); then
    echo "Kein JDK ab Version 17 gefunden. Bitte z. B. Eclipse Temurin von https://adoptium.net installieren." >&2
    exit 1
fi
echo "JDK: $JAVA_HOME_PFAD"

# 2. Anthropic-Java-SDK für den Claude-Coach laden (einmalig, mit Prüfsummen)
sh ./werkzeuge/sdk-laden.sh

# 3. App-Paket anlegen und Java-Teil vorübersetzen
BAU="$WURZEL/mac/build"
APP="$BAU/Java-Trainer.app"
RES="$APP/Contents/Resources/trainer"
rm -rf "$BAU"
mkdir -p "$APP/Contents/MacOS" "$RES/klassen"
echo "Übersetze Trainer.java ..."
"$JAVA_HOME_PFAD/bin/javac" -encoding UTF-8 -nowarn -cp "lib/*" -d "$RES/klassen" Trainer.java
cp -R kurs web lib "$RES/"

# 4. Swift-Hülle übersetzen (für die Architektur dieses Macs)
echo "Übersetze die App ..."
ARCH=$(uname -m)
xcrun swiftc -O -parse-as-library -target "$ARCH-apple-macos13.0" \
    mac/JavaTrainerApp.swift -o "$APP/Contents/MacOS/Java-Trainer"

# 5. App-Symbol
ICONSET="$BAU/AppIcon.iconset"
mkdir -p "$ICONSET"
for g in 16 32 128 256 512; do
    sips -z "$g" "$g" mac/AppIcon.png --out "$ICONSET/icon_${g}x${g}.png" >/dev/null
    sips -z $((g * 2)) $((g * 2)) mac/AppIcon.png --out "$ICONSET/icon_${g}x${g}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# 6. Info.plist
cp mac/Info.plist "$APP/Contents/Info.plist"

# 7. Ad-hoc signieren (nur für diesen Mac, keine Weitergabe)
codesign --force --deep --sign - "$APP"

# 8. In "Programme" installieren
ZIEL=/Applications
if [ ! -w "$ZIEL" ]; then
    ZIEL="$HOME/Applications"
    mkdir -p "$ZIEL"
fi
rm -rf "$ZIEL/Java-Trainer.app"
ditto "$APP" "$ZIEL/Java-Trainer.app"
rm -rf "$BAU"

echo ""
echo "Fertig: $ZIEL/Java-Trainer.app"
echo "Du findest den Java-Trainer jetzt in \"Programme\" und im Launchpad."
open "$ZIEL/Java-Trainer.app"
