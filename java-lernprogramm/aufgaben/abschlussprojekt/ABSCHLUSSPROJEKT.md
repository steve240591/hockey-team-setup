# Abschlussprojekt: Kaderverwaltung

In diesem Projekt baust du ein kleines Konsolenprogramm für eine Eishockeymannschaft. Es kommt **alles** aus dem Skript vor: Klassen, Datenkapselung, Konstruktoren, Vererbung, abstrakte Klassen, Schnittstellen, Klassenvariablen, Felder, Schleifen, `switch` und die Eingabe mit `Scanner`.

Anders als in den Modulen gibt es hier **keinen automatischen Prüfer**. Du testest selbst, indem du das Programm startest und die Menüpunkte ausprobierst. Das ist ganz normale Programmierarbeit.

**Startdatei:** `Kaderverwaltung.java`. Menü und Eingabe-Hilfsmethoden sind schon fertig.
**Musterlösung:** `loesungen/abschlussprojekt/Kaderverwaltung.java`. Schau erst hinein, wenn du fertig bist oder wirklich feststeckst.

---

## Das Klassendiagramm

```
            «abstract» Person                       «interface» Auswertbar
            - anzahlPersonen: int  {static}         + statistik(): String
            - name: String
            + getName(): String
            + getAnzahlPersonen(): int {static}
            + rolle(): String  {abstract}
                    △                                        △
                    │                                        ┆ implements
            «abstract» Spieler ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┘
            - nummer: int
            + getNummer(): int
            + toString(): String
                 △                △
        ┌────────┘                └────────┐
   Feldspieler                         Torhueter
   - tore: int                         - paraden: int
   - vorlagen: int                     - gegentore: int
   + torErzielen()                     + parade()
   + vorlageGeben()                    + gegentor()
   + punkte(): int                     + fangquote(): double
   + rolle(): String                   + rolle(): String
   + statistik(): String               + statistik(): String


   Kader
   - MAX_SPIELER = 25  {static final}
   - teamname: String
   - spieler: Spieler[]
   - anzahl: int
   + hinzufuegen(s: Spieler): boolean
   + suche(nummer: int): Spieler
   + topScorer(): Feldspieler
   + ausgeben()
```

---

## Stufe 1: Die Klassen

1. **Person** (abstrakt)
   - Hat einen privaten Namen, der im Konstruktor gesetzt wird.
   - Die Klassenvariable `anzahlPersonen` zählt, wie viele Personen erzeugt wurden (Modul 8).
   - Die abstrakte Methode `rolle()` liefert z. B. `"Feldspieler"`.
2. **Auswertbar** (Interface) mit der Methode `String statistik()`.
3. **Spieler** (abstrakt) erbt von `Person` und implementiert `Auswertbar`.
   - Hat zusätzlich eine Rückennummer.
   - Ruft im Konstruktor `super(name)` auf.
   - Überschreibt `toString()`, z. B. so: `#22 Plachta (Feldspieler)  Tore: 2  Vorlagen: 0  Punkte: 2`
4. **Feldspieler** zählt Tore und Vorlagen. Punkte = Tore + Vorlagen.
5. **Torhueter** zählt Paraden und Gegentore.
   - Fangquote in Prozent = Paraden / (Paraden + Gegentore) · 100.
   - Ohne Schüsse ist die Fangquote 0.
   - Pass auf die Ganzzahldivision auf (Modul 1)!

**Selbsttest:** Erzeuge in `main` testweise zwei Spieler und gib sie mit `System.out.println(...)` aus.

## Stufe 2: Der Kader

- Ein Feld `Spieler[] spieler` mit Platz für `MAX_SPIELER` Spieler, dazu ein Zähler `anzahl`.
- `hinzufuegen(...)` gibt `false` zurück, wenn der Kader voll ist oder die Nummer schon vergeben ist. Sonst wird der Spieler gespeichert und die Methode gibt `true` zurück.
- `suche(nummer)` liefert den Spieler oder `null`.
- `topScorer()` liefert den Feldspieler mit den meisten Punkten. Torhüter werden mit `instanceof` übersprungen (Modul 7, Aufgabe 5).
- `ausgeben()` gibt alle Spieler und die Anzahl erzeugter Personen aus.

## Stufe 3: Das Menü

Setze im `switch` in `main` die Menüpunkte 1 bis 7 um:

| Nr. | Funktion |
|---|---|
| 1 / 2 | Feldspieler bzw. Torhüter anlegen: Name und Nummer einlesen. Nummer nur von 1 bis 99. |
| 3 / 4 | Tor bzw. Vorlage eintragen: Nummer einlesen, Spieler suchen, prüfen, ob es ein Feldspieler ist. |
| 5 | Schuss auf Torhüter: „1 = gehalten, 2 = Gegentor“. |
| 6 | Kader anzeigen |
| 7 | Topscorer anzeigen |

Tipp: Schreib für jeden Menüpunkt eine eigene kleine `static`-Methode. Dann bleibt `main` übersichtlich.

## Stufe 4: Erweiterungen (freiwillig)

- **Spieler entfernen:** Nachfolgende Spieler im Feld eine Position nach vorne schieben.
- **Tabelle sortiert nach Punkten** ausgeben, z. B. mit Bubblesort auf einer Kopie des Feldes.
- **Trainer** als weitere Subklasse von `Person`. Der Trainer ist kein Spieler, hat also keine Nummer!
- **Teamstatistik:** Tore gesamt und Fangquote aller Torhüter zusammen.

---

## Checkliste für sauberen Code

- [ ] Klassennamen beginnen groß, Methoden und Variablen klein, Konstanten GROSS (Skript S. 9).
- [ ] Alle Instanzvariablen sind `private` (Datenkapselung).
- [ ] Keine Methode ist länger als etwa 20–30 Zeilen. Wird eine länger, teile sie auf.
- [ ] Namen sagen, was gemeint ist: `anzahlSpieler` statt `a` oder `x`.
- [ ] Gleiche Logik steht nur an **einer** Stelle, z. B. `punkte()` statt `tore + vorlagen` an fünf Stellen.
- [ ] Einheitliche Einrückung (4 Leerzeichen) und geschweifte Klammern auch bei einzeiligen `if`s.
- [ ] Kommentare erklären das **Warum**, nicht das Offensichtliche.
