#!/bin/sh
# Baut die macOS-App "Java-Trainer" und installiert sie im Ordner "Programme".
#
# Aufruf im Terminal (im Ordner java-lernprogramm):
#     sh mac/app-bauen.sh
# oder Doppelklick auf "mac/App bauen.command".
#
# Voraussetzungen: macOS 13 oder neuer, Xcode oder die Command Line Tools
# (xcode-select --install) und ein JDK ab Version 17.
# Nach Änderungen an den Lektionen einfach erneut ausführen.
set -e
cd "$(dirname "$0")/.."
WURZEL=$(pwd)
SCHRITT="Start"
FERTIG=0

# Bricht ein Schritt ab, sagen wir deutlich, welcher es war.
melde_abbruch() {
    if [ "$FERTIG" != 1 ]; then
        echo "" >&2
        echo "==================================================================" >&2
        echo "ABBRUCH beim Schritt: $SCHRITT" >&2
        echo "Es wurde nichts in \"Programme\" installiert." >&2
        echo "Bitte die Ausgabe oben (oder mac/bauprotokoll.txt) an Claude schicken." >&2
        echo "==================================================================" >&2
    fi
}
trap melde_abbruch EXIT

# Reste eines früheren, abgebrochenen Baus entfernen (halbfertige App!)
rm -rf "$WURZEL/mac/build"

SCHRITT="Voraussetzungen prüfen"
echo "1/7 $SCHRITT ..."
if [ "$(uname)" != "Darwin" ]; then
    echo "Dieses Skript läuft nur auf macOS." >&2
    exit 1
fi
if ! xcrun --find swiftc >/dev/null 2>&1; then
    echo "Swift-Compiler nicht gefunden. Bitte Xcode installieren oder im Terminal ausführen: xcode-select --install" >&2
    exit 1
fi
# Ein JDK ab Version 17 suchen. Wichtig: Es muss javac enthalten - eine reine
# Laufzeitumgebung (JRE, z. B. das alte Java-Browser-Plug-in) reicht nicht.
java_version() {
    "$1/bin/java" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'
}
JAVA_HOME_PFAD=""
for kandidat in "$(/usr/libexec/java_home -v 17+ 2>/dev/null)" \
        /Library/Java/JavaVirtualMachines/*/Contents/Home \
        "$HOME"/Library/Java/JavaVirtualMachines/*/Contents/Home \
        /opt/homebrew/opt/openjdk*/libexec/openjdk.jdk/Contents/Home \
        /usr/local/opt/openjdk*/libexec/openjdk.jdk/Contents/Home; do
    if [ -x "$kandidat/bin/javac" ] && [ -x "$kandidat/bin/java" ]; then
        v=$(java_version "$kandidat")
        case "$v" in
            ''|*[!0-9]*) continue ;;
        esac
        if [ "$v" -ge 17 ]; then
            JAVA_HOME_PFAD="$kandidat"
            break
        fi
    fi
done
if [ -z "$JAVA_HOME_PFAD" ]; then
    echo "Kein JDK ab Version 17 mit Compiler (javac) gefunden." >&2
    echo "Bitte ein JDK installieren, z. B. Eclipse Temurin 21 (LTS) für macOS von https://adoptium.net" >&2
    echo "Gefunden wurde nur: $(/usr/libexec/java_home 2>/dev/null)" >&2
    exit 1
fi
echo "    macOS $(sw_vers -productVersion), $(uname -m)"
echo "    JDK: $JAVA_HOME_PFAD (Version $(java_version "$JAVA_HOME_PFAD"))"
echo "    $(xcrun swiftc --version 2>&1 | head -1)"

SCHRITT="Anthropic-SDK laden"
echo "2/7 $SCHRITT (einmalig, ca. 45 MB) ..."
sh ./werkzeuge/sdk-laden.sh

# Gebaut wird in einem temporären Ordner - eine halbfertige App kann so
# nirgends liegen bleiben.
BAU=$(mktemp -d "${TMPDIR:-/tmp}/javatrainer.XXXXXX")
APP="$BAU/Java-Trainer.app"
RES="$APP/Contents/Resources/trainer"
mkdir -p "$APP/Contents/MacOS" "$RES/klassen"

SCHRITT="Java-Teil übersetzen"
echo "3/7 $SCHRITT ..."
"$JAVA_HOME_PFAD/bin/javac" -encoding UTF-8 -nowarn -cp "lib/*" -d "$RES/klassen" Trainer.java
cp -R kurs web lib "$RES/"
# Die App merkt sich, mit welchem JDK sie gebaut wurde.
printf '%s\n' "$JAVA_HOME_PFAD" > "$RES/jdk-pfad.txt"

SCHRITT="App übersetzen (Swift)"
echo "4/7 $SCHRITT ..."
ARCH=$(uname -m)
xcrun swiftc -O -parse-as-library -swift-version 5 -target "$ARCH-apple-macos13.0" \
    mac/JavaTrainerApp.swift -o "$APP/Contents/MacOS/Java-Trainer"

SCHRITT="App-Symbol und Info.plist"
echo "5/7 $SCHRITT ..."
ICONSET="$BAU/AppIcon.iconset"
mkdir -p "$ICONSET"
for g in 16 32 128 256 512; do
    sips -z "$g" "$g" mac/AppIcon.png --out "$ICONSET/icon_${g}x${g}.png" >/dev/null
    sips -z $((g * 2)) $((g * 2)) mac/AppIcon.png --out "$ICONSET/icon_${g}x${g}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cp mac/Info.plist "$APP/Contents/Info.plist"

SCHRITT="App prüfen und signieren"
echo "6/7 $SCHRITT ..."
if [ ! -x "$APP/Contents/MacOS/Java-Trainer" ]; then
    echo "Die Programmdatei der App fehlt." >&2
    exit 1
fi
plutil -lint "$APP/Contents/Info.plist" >/dev/null
# Quarantäne-Markierungen (z. B. vom ZIP-Download) entfernen, dann ad hoc signieren
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

SCHRITT="In \"Programme\" installieren"
echo "7/7 $SCHRITT ..."
ZIEL=/Applications
if [ ! -w "$ZIEL" ]; then
    ZIEL="$HOME/Applications"
    mkdir -p "$ZIEL"
fi
rm -rf "$ZIEL/Java-Trainer.app"
ditto "$APP" "$ZIEL/Java-Trainer.app"
rm -rf "$BAU"

FERTIG=1
echo ""
echo "Fertig: $ZIEL/Java-Trainer.app"
echo "Du findest den Java-Trainer jetzt in \"Programme\" und im Launchpad."
open "$ZIEL/Java-Trainer.app"
