# Modul 10: Musterlösung

Erst anschauen, wenn du alle Fragen selbst beantwortet hast!
Die Seitenzahlen beziehen sich auf das Skript. Die Ausgaben in Teil B und die Compilerfehler in Teil C habe ich mit OpenJDK 21 geprüft.

---

## Teil A

1. **Erstellen** des Quelltexts mit einem Editor (`HalloJava.java`). **Übersetzen** mit dem Compiler `javac HalloJava.java`, dabei entsteht `HalloJava.class`. **Ausführen** mit dem Interpreter bzw. der JVM: `java HalloJava` (S. 6/7).
2. Byte-Code ist der plattformunabhängige Code, den `javac` erzeugt (`.class`-Dateien). Die JVM ist die Schnittstelle zwischen Byte-Code und dem jeweiligen System. Sie lädt, prüft und führt den Byte-Code aus. Für jedes Betriebssystem gibt es eine eigene JVM, der Byte-Code bleibt aber derselbe: „write once, run everywhere“ (S. 6).
3. `Torjaeger.java`, weil der Dateiname dem Namen der public-Klasse entsprechen muss. Eine Datei darf **höchstens eine** public-Klasse enthalten, aber beliebig viele weitere Klassen (S. 7, 11).
4. Ganzzahlig: `byte`, `short`, `int`, `long`. Fließkomma: `float`, `double`. Zeichen: `char`. Logisch: `boolean` (S. 18).
5. `&&` ist der Short-Cut-Operator: Ist der linke Ausdruck schon `false`, wird der rechte **nicht mehr ausgewertet**. `&` wertet immer beide Seiten aus. Das ist wichtig, wenn der rechte Teil nur unter einer Bedingung sicher ist, z. B. `z != 0 && 10 / z > 1`. Mit `&` gäbe es bei `z == 0` eine Division durch 0 (S. 20).
6. Automatisch geht es nur vom niederwertigen zum höherwertigen Typ: `byte → short → int → long → float → double` und `char → int`. Beispiel: `double d = 5;`. In die andere Richtung braucht man einen Cast: `int i = (int) 2.538;` ergibt 2, weil der Nachkommateil abgeschnitten und nicht gerundet wird (S. 19/20).
7. `while` prüft die Bedingung **vor** jedem Durchlauf (abweisende Schleife) und läuft eventuell kein einziges Mal. `do-while` prüft die Bedingung **nach** dem Durchlauf (nicht abweisend) und läuft deshalb mindestens einmal (S. 22).
8. Die Ausführung „fällt durch“: Alle folgenden `case`-Zweige werden ebenfalls ausgeführt, bis ein `break` kommt oder der `switch` endet. Ein `case` ist nur ein Einsprungziel (S. 22). Siehe B2.
9. Die **Klasse** `Fahrrad` ist der Bauplan. `meinRad` ist ein **Objekt** bzw. eine Referenzvariable vom Typ `Fahrrad`. `new Fahrrad()` erzeugt eine konkrete **Instanz** im Speicher, und `meinRad` verweist darauf (S. 23–25).
10. Auf die Daten eines Objekts wird nicht direkt von außen zugegriffen. Der Zugriff läuft nur über Methoden („Nachrichten“). Umsetzung: Instanzvariablen werden `private`, der Zugriff erfolgt über öffentliche get- und set-Methoden. Diese können Werte auch prüfen (S. 28/29, Modul 6 Aufgabe 4).
11. (a) Wenn ein Parameter genauso heißt wie eine Instanzvariable: `this.farbe = farbe;` (S. 29). (b) Um aus einem Konstruktor einen anderen Konstruktor derselben Klasse aufzurufen: `this(f.eigentuemer, f.farbe);` (S. 30).
12. Ein Konstruktor ist eine spezielle Methode mit dem Namen der Klasse und ohne Rückgabetyp. Er wird bei `new` aufgerufen und setzt die Startwerte (S. 30). **Genauer als im Skript:** Java erzeugt den parameterlosen Standardkonstruktor **nur dann**, wenn die Klasse **keinen einzigen** Konstruktor deklariert. Sobald man z. B. nur `Rad(String farbe)` schreibt, schlägt `new Rad()` fehl (siehe C2). Das regelt die Java Language Specification in §8.8.9 „Default Constructor“.
13. **Überladen:** gleicher Methodenname, aber eine **andere Parameterliste**, in derselben Klasse. Beispiel: mehrere Konstruktoren von `Fahrrad4` oder `torErzielen()` und `torErzielen(int)` (S. 30). **Überschreiben:** Eine Subklasse definiert eine Methode mit **gleicher Signatur** wie die Basisklasse neu, z. B. `flaeche()` in `Zylinder` (S. 33).
14. `super.flaeche()` ruft die (überschriebene) **Methode** der Basisklasse auf. `super()` ruft den **Konstruktor** der Basisklasse auf und muss die **erste Anweisung** im Konstruktor sein (S. 34).
15. Erst zur Laufzeit wird entschieden, welche Methode ausgeführt wird. Das richtet sich nach der **tatsächlichen Instanz**, nicht nach dem deklarierten Typ der Variable. Bei `Kreis k = new Zylinder()` wird deshalb `flaeche()` aus `Zylinder` aufgerufen (S. 34/35).
16. `final class`: Von der Klasse darf keine Subklasse gebildet werden. `final`-Methode: Sie darf nicht überschrieben werden. `final`-Variable: eine Konstante, der Wert kann nicht mehr geändert werden (S. 35, 37).
17. Eine Klassenvariable (`static`) gibt es **einmal pro Klasse**, alle Instanzen teilen sie (Beispiel `num_kreise`). Jede Instanz hat ihre **eigenen** Instanzvariablen. Eine statische Methode gehört zu keiner Instanz, sie hat kein `this`. Deshalb weiß sie nicht, wessen Instanzvariable gemeint wäre (S. 36/37, siehe C3).
18. Eine abstrakte Klasse kann normale Instanzvariablen und fertige Methoden enthalten, z. B. `setPos()` in `Figur`, dazu abstrakte Methoden. Ein Interface enthält laut Skript nur abstrakte Methoden und Konstanten (S. 40). Eine Klasse erbt nur von **einer** Klasse, weil Java keine Mehrfachvererbung hat (S. 32), kann aber **mehrere** Interfaces implementieren. Interfaces „ersetzen“ so die Mehrfachvererbung (S. 40). **Ergänzung zum Skript:** Seit Java 8 dürfen Interfaces zusätzlich `default`- und `static`-Methoden mit Rumpf enthalten. Ich habe das mit JDK 21 ausprobiert, Grundlage ist Java Language Specification §9.4.
19. `public` (überall) > `protected` (eigenes Paket und alle Subklassen) > kein Modifikator (nur im eigenen Paket) > `private` (nur in der eigenen Klasse) (S. 41/42).
20. Von abstrakten Klassen können keine Instanzen erzeugt werden (S. 38). Eine **Referenz** vom Typ `Figur` darf aber auf eine Instanz einer konkreten Subklasse zeigen, das ist die Grundlage der dynamischen Bindung.

---

## Teil B

| Aufgabe | Ausgabe | Erklärung |
|---|---|---|
| B1 | `0 1 2 3 ` | `while` gibt 0, 1, 2 aus. Danach ist `i == 3`, aber `do-while` läuft trotzdem **einmal** und gibt 3 aus. |
| B2 | `vier fuenf ende` | Einsprung bei `case 4`, ohne `break` fällt die Ausführung bis zum Ende durch. |
| B3 | `3345` | Von links nach rechts: `1 + 2 = 3` (Zahlen), dann `3 + "3" = "33"` (String), dann `"334"`, dann `"3345"`. |
| B4 | `3 3.0 3.5` | `7 / 2` ist eine Ganzzahldivision. Das gilt auch, wenn das Ergebnis danach in einer `double`-Variable landet. |
| B5 | `3 3` | `n` ist eine Klassenvariable und existiert nur einmal. `zz.n` ist dieselbe Variable (besser so schreiben: `Z.n`, S. 36). |
| B6 | `Zylinder` | `getClass()` liefert die Klasse der tatsächlichen Instanz. |
| B7 | `1 20 11` | `10 > 3`, also `10 % 3 = 1`. `a++ * 2` rechnet mit dem alten Wert 10 und ergibt 20. Danach ist `a == 11`. |

---

## Teil C

| Aufgabe | Fehler | Meldung von `javac` (JDK 21) |
|---|---|---|
| C1 | Semikolon fehlt nach `int zahl = 5` | `';' expected` |
| C2 | Es gibt nur `Rad(String)`, deshalb keinen automatischen Standardkonstruktor | `constructor Rad in class Rad cannot be applied to given types` |
| C3 | Eine statische Methode greift auf eine Instanzvariable zu | `non-static variable wert cannot be referenced from a static context` |
| C4 | Interface-Methoden sind automatisch `public`. Die Klasse muss `public void moveX(int m)` schreiben | `moveX(int) in Puck cannot implement moveX(int) in Bewegung` (mit dem Hinweis „attempting to assign weaker access privileges“) |
| C5 | `int` lässt sich nicht in `boolean` umwandeln, anders als in C (S. 19) | `incompatible types: int cannot be converted to boolean` |

---

## Teil D

Siehe Ordner `modul10_pakete/`. So startest du die Lösung:

```
cd loesungen/modul10_pakete
javac PaketTest.java
java PaketTest
```

Ausgabe:
```
 Komma | 
 Strich - 
```

Es entstehen `PaketTest.class` sowie `MeinPak/Komma.class` und `MeinPak/Strich.class`. Der Compiler übersetzt die Klassen im Paket „bei Bedarf“ gleich mit (S. 18).

**Zusatzfrage:** Ohne `public` ist `Komma` nur innerhalb des Pakets `MeinPak` sichtbar (S. 17, 42). `PaketTest` liegt außerhalb und kann die Klasse nicht verwenden. `javac` meldet dann bei `import MeinPak.*;` den Fehler `cannot find symbol ... Komma`.

**Hinweis zur Namenskonvention:** Das Skript nennt das Paket `MeinPak`. In der Praxis schreibt man Paketnamen in Java üblicherweise komplett klein (z. B. `meinpak`). Das ist eine Konvention, Großbuchstaben funktionieren technisch trotzdem.
