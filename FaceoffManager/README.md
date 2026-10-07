# Faceoff Manager – erster Entwurf

Eishockey-Idle-Manager für iOS (SwiftUI + SpriteKit), gebaut nach dem Spielkonzept.
Dieser Ordner ist unabhängig von der App „EishockeyAufstellung“ im selben Repository.

## Was im ersten Entwurf drin ist

| Bereich | Stand |
| --- | --- |
| 9 Einrichtungen mit Ausbau, Managern, Meilensteinen (×2 bei Stufe 25/50/100) | fertig |
| Kader: 6 Positionen, 4 Seltenheiten, Training mit Karten, Scouting mit angezeigten Wahrscheinlichkeiten | fertig |
| Automatische Spiele, Tabelle, Aufstieg über die Ligen 1 bis 5 (kein Abstieg) | fertig |
| Penalty-Schießen als Minispiel (bei Unentschieden und als Training) | fertig |
| Prestige mit Legendenpunkten | fertig |
| Offline-Einnahmen, 7-Tage-Login-Kalender, 3 tägliche Aufgaben | fertig |
| In-App-Käufe mit StoreKit 2 (Starterpaket, Werbefrei, 4 Puck-Pakete) | fertig, Produkte müssen noch angelegt werden |
| Belohnungsvideos | **simuliert** (5-Sekunden-Testvideo). Google AdMob folgt im nächsten Schritt |
| Deutsch und Englisch | fertig |
| Grafiken | **Platzhalter** (SF Symbols und Formen). Liste der Bilder: [BILDER.md](BILDER.md) |
| iCloud-Sicherung, Promo-Codes, Overtime-Finale | später |

Alle Spielwerte (Preise, Tempo, Belohnungen, Teams) stehen in `Game/Resources/GameConfig.json`
und lassen sich ohne Programmierung ändern.

## Einmalige Einrichtung in Xcode

Voraussetzung: Mac mit **Xcode 16 oder neuer**.

1. **Repository holen:** Im Terminal in den Repository-Ordner wechseln und den Branch auschecken:
   ```
   git fetch origin
   git checkout claude/game-app-monetization-strategy-5utzt2
   ```
2. **Neues Projekt anlegen:** Xcode → *File → New → Project… → iOS → App*.
   - Product Name: `FaceoffManager`
   - Team: dein Apple-Developer-Team
   - Organization Identifier: z. B. `de.deinname` (ergibt die Bundle-ID)
   - Interface: **SwiftUI**, Language: **Swift**, Testing System: **None**, Storage: **None**
   - Speicherort: den Ordner **`FaceoffManager`** in diesem Repository wählen (der Ordner, in dem diese README liegt).
   - Haken bei „Create Git repository“ **entfernen**, das Repository gibt es schon.
3. **Vorlagen-Dateien löschen:** Im linken Projektnavigator `ContentView.swift` und `FaceoffManagerApp.swift`
   markieren → Rechtsklick → *Delete* → *Move to Trash*. `Assets.xcassets` bleibt.
4. **Spielcode einbinden:** Den Ordner `FaceoffManager/Game` aus dem Finder in den Projektnavigator ziehen,
   direkt auf den gelben Ordner `FaceoffManager`. Im Dialog:
   - Dateien **nicht kopieren** („Reference files in place“ bzw. Haken bei „Copy items if needed“ aus)
   - **Ordner** statt Gruppen anlegen („Create folders“; der Ordner erscheint dann blau)
   - Target `FaceoffManager` angehakt

   Vorteil: Neue Dateien, die ich später hinzufüge, erscheinen nach `git pull` automatisch im Projekt.
5. **Einstellungen im Target `FaceoffManager` → General:**
   - Minimum Deployments: **iOS 17.0**
   - Device Orientation: nur **Portrait** anhaken
6. **Sprachen:** Projekt (blaues Symbol ganz oben) → *Info* → *Localizations* → „+“ → **German** hinzufügen.
7. **Swift-Sprachmodus prüfen:** Target → *Build Settings* → Suche „Swift Language Version“ → **Swift 5**.
8. **Starten:** Oben ein iPhone-Simulator oder dein iPhone wählen → ▶︎.

Zeigt Xcode beim Bauen Fehler, schick mir bitte einen Screenshot oder den Fehlertext.
Ich konnte den Code in meiner Umgebung nicht kompilieren (dort gibt es kein Xcode).

## In-App-Käufe testen

**Schnelltest ohne Einrichtung:** Im Shop gibt es in Testversionen den Abschnitt „Nur Testversion“
mit „Kauf simulieren“. Er fehlt automatisch in der App-Store-Version.

**Echter StoreKit-Test im Simulator:**

1. *File → New → File… → StoreKit Configuration File*, Name `Products`, Speicherort `FaceoffManager/`.
2. Mit „+“ diese Produkte anlegen:

   | Typ | Product ID | Preis |
   | --- | --- | --- |
   | Non-Consumable | `faceoff.starterpack` | 0,99 € |
   | Non-Consumable | `faceoff.adfree` | 4,99 € |
   | Consumable | `faceoff.pucks.80` | 0,99 € |
   | Consumable | `faceoff.pucks.500` | 4,99 € |
   | Consumable | `faceoff.pucks.1100` | 9,99 € |
   | Consumable | `faceoff.pucks.2400` | 19,99 € |

3. *Product → Scheme → Edit Scheme… → Run → Options → StoreKit Configuration* → `Products.storekit`.

Vor der Veröffentlichung müssen dieselben Produkt-IDs in App Store Connect angelegt werden.

## Tests der Spiellogik

Die Spiellogik (`Game/Core`) hat automatische Tests. Im Terminal:

```
cd FaceoffManager
swift test
```

## Ordnerstruktur

| Ordner | Inhalt |
| --- | --- |
| `Game/Core` | Spiellogik ohne Oberfläche: Wirtschaft, Spiele, Saison, Prestige, Tagesaufgaben |
| `Game/App` | App-Start, Verbindung von Logik und Oberfläche (`GameStore`), Texte und Zahlenformate |
| `Game/Views` | Bildschirme: Verein, Team, Liga, Shop, Mehr, Ergebnisfenster |
| `Game/MiniGame` | Penalty-Schießen mit SpriteKit |
| `Game/Services` | Speichern, In-App-Käufe, Belohnungsvideos |
| `Game/Resources` | `GameConfig.json` (alle Spielwerte), `Localizable.xcstrings` (Deutsch/Englisch) |
| `Tests` | Automatische Tests der Spiellogik |
