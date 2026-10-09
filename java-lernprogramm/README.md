# Java-Übungsprogramm: Objektorientierte Programmierung, Teil 1

Ein Übungsprogramm zum Skript **„Sprache, Elemente, Strukturen, Klassen – Teil 1 OOP“** (Lektionen 1–13).
Reihenfolge, Begriffe und Beispiele folgen dem Skript, also Fahrrad, Kreis/Zylinder sowie Figur/Bewegung. Damit es nicht nur Fahrräder sind, kommen ein paar Eishockey-Beispiele dazu.

Jede Aufgabendatei **prüft sich selbst**. Du startest sie und siehst sofort, was schon stimmt:

```
Aufgabe 2 - celsiusInFahrenheit
  [OK]      celsiusInFahrenheit(100.0)
  [FEHLER]  celsiusInFahrenheit(37.0)
            erwartet: 98.6
            erhalten: 69.0
  [OFFEN]   celsiusInFahrenheit(-40.0)
```

---

## Ordnerstruktur

```
java-lernprogramm/
├── README.md                      ← diese Anleitung mit Lernplan
├── aufgaben/                      ← HIER arbeitest du
│   ├── Modul01_Datentypen.java
│   ├── ...
│   ├── Modul09_AbstraktInterface.java
│   ├── Modul10_Wiederholung.md    ← Klausur-Training ohne Prüfer
│   └── abschlussprojekt/
└── loesungen/                     ← Musterlösungen (erst NACH dem eigenen Versuch!)
```

---

## Voraussetzungen und Start

1. **JDK 17 oder neuer** installieren. Am besten eine LTS-Version (das Skript nennt J17, J21 und J25 auf S. 4). Getestet ist alles mit OpenJDK 21.
2. Test in der Kommandozeile: `java -version` sollte die Version anzeigen.
3. Ins Aufgabenverzeichnis wechseln und ein Modul starten:

```
cd java-lernprogramm/aufgaben
java Modul01_Datentypen.java
```

Oder klassisch in zwei Schritten wie im Skript (S. 7):

```
javac Modul01_Datentypen.java
java Modul01_Datentypen
```

Das funktioniert auch in jeder Entwicklungsumgebung (IntelliJ, Eclipse, VS Code, BlueJ …): Datei öffnen und `main` ausführen.

**Bedeutung der Ausgaben**

| Ausgabe | Bedeutung |
|---|---|
| `[OK]` | richtig gelöst |
| `[FEHLER]` | Ergebnis falsch. Darunter stehen erwarteter und erhaltener Wert. |
| `[OFFEN]` | Die Zeile `throw new UnsupportedOperationException("TODO");` steht noch da. |
| `[ABSTURZ]` | Dein Code hat einen Laufzeitfehler, z. B. Index außerhalb des Feldes. |

Kompiliert die Datei gar nicht, zeigt Java die Fehlermeldung mit Zeilennummer an. Lies sie genau, sie verrät fast immer die Ursache.

---

## So arbeitest du (bitte wirklich so!)

1. **Skript-Lektion lesen.** Jedes Modul nennt die passenden Seiten.
2. **Aufgabe selbst lösen.** Ersetze die `throw`-Zeile durch deinen Code. Nicht abschreiben, selbst tippen!
3. **Starten und Ausgabe lesen.** Bei `[FEHLER]`: erwarteten und erhaltenen Wert vergleichen und überlegen, woher der Unterschied kommt.
4. **Feststecken?** Nach etwa 20 Minuten: Hinweise im Kommentar lesen, Skriptseite nochmal ansehen, Zwischenwerte mit `System.out.println(...)` ausgeben.
5. **Erst wenn alles `[OK]` ist** (oder du nach langem Versuchen wirklich nicht weiterkommst): mit der Musterlösung vergleichen. Oft gibt es mehrere richtige Lösungen. Frag dich, welche lesbarer ist.
6. **Wiederholen.** Ein paar Tage später ein Modul nochmal von vorn lösen. Das kostet wenig Zeit und bringt viel. Mit `git checkout -- aufgaben/` setzt du alles auf den Ausgangszustand zurück. Oder du arbeitest gleich in einer Kopie des Ordners.

Die **„Vorhersage“-Aufgaben** (Module 2, 5 und 8) sind besonders klausurnah. Dort schreibst du keinen Algorithmus. Du überlegst auf Papier, was ein Stück Code ergibt, und gibst deinen Tipp mit `return` zurück.

---

## Lernplan

Die Zeitangaben sind **meine Schätzung als Richtwert** für jemanden ohne Vorkenntnisse. Sie sind nicht gemessen. Nimm dir so viel Zeit, wie du brauchst.

| Woche | Modul | Thema | Skript | Prüfungen | Richtwert |
|---|---|---|---|---|---|
| 1 | 01 | Grunddatentypen, Typkonvertierung, Strings | L4, L5, L7 (S. 8–19) | 24 | 2–3 h |
| 1 | 02 | Operatoren, Ausdrücke, Vorhersagen | L7 (S. 20–21) | 29 | 2–3 h |
| 2 | 03 | Kontrollstrukturen (if, switch, Schleifen, break/continue) | L7 (S. 21–23) | 32 | 3–4 h |
| 2 | 04 | Arrays und Strings | S. 13–15, 22, 35 | 22 | 3–4 h |
| 3 | 05 | Klassen, Objekte, Instanzmethoden | L8 (S. 23–28) | 14 | 2–3 h |
| 3 | 06 | Datenkapselung, Konstruktoren, this, Überladen | L9 (S. 28–30) | 22 | 3–4 h |
| 4 | 07 | Vererbung, super, Überschreiben, dynamische Bindung | L10 (S. 31–35) | 20 | 3–4 h |
| 4 | 08 | Klassenvariablen, Klassenmethoden, Konstanten | L11 (S. 36–38) | 10 | 1–2 h |
| 5 | 09 | Abstrakte Klassen und Schnittstellen | L12 (S. 38–40) | 13 | 2–3 h |
| 5 | 10 | Wiederholung, Pakete, Modifikatoren (Klausur-Training) | L1, L2, L6, L13 | – | 3–4 h |
| 6 | – | Abschlussprojekt Kaderverwaltung | alles | – | 6–10 h |

Lektion 3 (Hallo Java) steckt in jedem Modul, weil du jedes Mal übersetzt und startest.

---

## Typische Anfängerfehler (die in den Aufgaben absichtlich vorkommen)

| Fehler | Beispiel | Modul |
|---|---|---|
| Ganzzahldivision | `9 / 5` ergibt `1`, `7 / 2` ergibt `3` | 1, 10 |
| Überlauf bei `int` | `100 * 365 * 24 * 60 * 60` wird negativ | 1 |
| `char + char` ist eine Zahl | `'W' + '.'` ergibt `133` | 1 |
| String-Verkettung von links | `"Summe: " + 3 + 4` ergibt `"Summe: 34"` | 1, 2 |
| `&` statt `&&` | Der rechte Teil wird trotzdem ausgewertet | 2 |
| `break` vergessen | `switch` fällt in den nächsten `case` | 3, 10 |
| Maximum mit 0 starten | Falsches Ergebnis bei lauter negativen Zahlen | 4 |
| `=` bei Objekten | kopiert nur die Referenz, nicht das Objekt | 5 |
| `this` vergessen | `name = name;` ändert die Instanzvariable nicht | 6 |
| Überschriebene statt geerbte Methode | `flaeche()` statt `super.flaeche()` | 7 |

---

## Hinweise zum Skript

An drei Stellen ist das Skript etwas vereinfacht. Ich habe jede davon mit JDK 21 ausprobiert:

1. **Standardkonstruktor (S. 25 und 30):** Das Skript sagt, jede Klasse hat mindestens den Standardkonstruktor. Genau genommen erzeugt Java ihn **nur, wenn die Klasse keinen eigenen Konstruktor hat**. Hat eine Klasse nur `Rad(String farbe)`, dann schlägt `new Rad()` beim Übersetzen fehl. Quelle: Java Language Specification §8.8.9. Siehe auch Modul 10, Aufgabe C2.
2. **Statische Methoden (S. 42):** Dort steht, `static` sei „implizit auch final“. Das stimmt so nicht. Eine Subklasse darf eine statische Methode mit gleicher Signatur deklarieren, die die alte dann **verdeckt** („hiding“). Das ist nur verboten, wenn die Methode der Basisklasse ausdrücklich `final` ist. Quelle: Java Language Specification §8.4.3.3 und §8.4.8.2.
3. **Schnittstellen (S. 40):** Laut Skript enthalten Interfaces nur abstrakte Methoden und Konstanten. Seit Java 8 sind zusätzlich `default`- und `static`-Methoden mit Rumpf erlaubt. Quelle: Java Language Specification §9.4. Für die Klausur gilt natürlich, was in eurer Vorlesung behandelt wurde.

Außerdem rechnet das Skript mit `3.14`. Die Übungen verwenden das genauere `Math.PI`, das im Skript auf S. 37 vorgestellt wird.

---

## Was (noch) nicht drin ist

Das Übungsprogramm deckt nur den Stoff von **Teil 1** ab. Folgende Themen kommen im Skript nicht vor und fehlen deshalb auch hier: Ausnahmebehandlung (`try`/`catch`), Collections (`ArrayList`, `HashMap`), Generics, Lambdas und Streams, Dateien sowie GUI. Laut Skript (S. 7) wird die GUI-Programmierung in Teil 2 ausführlich behandelt.

---

## Kleingedrucktes

- Die Dateien sind in UTF-8 gespeichert. Umlaute stehen nur in Kommentaren. Ab Java 18 liest `javac` Quelltexte standardmäßig als UTF-8 (JEP 400). Ältere JDKs nehmen die Kodierung des Systems. Unter Windows (windows-1252) kompiliert alles trotzdem, nur die Umlaute in Kommentaren sehen dann seltsam aus. Bei anderen Systemkodierungen hilft `javac -encoding UTF-8 Datei.java`.
- Je nach Konsole können Umlaute in der **Ein- und Ausgabe** als `?` erscheinen. Das ist eine Einstellung der Konsole und kein Fehler in deinem Code. Deshalb verwenden die Testausgaben „ae, oe, ue“.
- Startest du eine Datei direkt mit `java Datei.java`, muss die Klasse mit `main` die **erste** Klasse in der Datei sein.
