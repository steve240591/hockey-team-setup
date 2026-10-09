# Modul 10: Wiederholung, Pakete und Modifikatoren

Passend zum Skript: Lektion 1–2 (Java und JDK), Lektion 6 (API und Pakete) und Lektion 13 (Deklarationen und Modifikatoren). Dazu kommt eine Wiederholung aller anderen Lektionen.

Dieses Modul hat keinen automatischen Prüfer. Beantworte die Fragen **schriftlich und ohne Hilfsmittel**, so wie in einer Klausur. Vergleiche danach mit `loesungen/Modul10_Wiederholung.md`. Die Seitenzahlen beziehen sich auf das Skript.

---

## Teil A: Verständnisfragen

**Java und Werkzeuge**

1. Welche drei Arbeitsschritte braucht man, um ein Java-Programm vom Quelltext bis zur Ausgabe zu bringen? Nenne jeweils das Werkzeug.
2. Was ist Java-Byte-Code, und welche Aufgabe hat die Java Virtual Machine (JVM)? Warum ist Java dadurch plattformunabhängig?
3. Wie muss die Datei heißen, in der `public class Torjaeger { ... }` steht? Wie viele public-Klassen darf eine Datei enthalten?
4. Nenne die vier Gruppen der Grunddatentypen und alle acht Grunddatentypen.

**Imperative Elemente**

5. Was ist der Unterschied zwischen `&` und `&&`? Wann ist er wichtig?
6. Welche Typkonvertierungen macht Java automatisch? Wann brauchst du den Cast-Operator? Gib je ein Beispiel.
7. Was ist der Unterschied zwischen einer `while`- und einer `do-while`-Schleife?
8. Was passiert in einer klassischen `switch`-Anweisung, wenn ein `break` fehlt?

**Objektorientierung**

9. Erkläre die Begriffe Klasse, Objekt und Instanz am Beispiel `Fahrrad meinRad = new Fahrrad();`.
10. Was bedeutet Datenkapselung? Wie setzt man sie in Java um?
11. Wozu braucht man `this`? Nenne zwei Situationen.
12. Was ist ein Konstruktor? Wann erzeugt Java automatisch einen Standardkonstruktor, und wann **nicht**?
13. Was ist der Unterschied zwischen **Überladen** und **Überschreiben**?
14. Was ist der Unterschied zwischen `super.flaeche()` und `super()`? Wo muss `super()` stehen?
15. Was versteht man unter dynamischer Bindung? Welche Methode wird bei `Kreis k = new Zylinder(); k.flaeche();` aufgerufen?
16. Was bewirkt `final` vor einer Klasse, vor einer Methode und vor einer Variablen?
17. Was ist der Unterschied zwischen einer Klassenvariable und einer Instanzvariable? Warum kann eine statische Methode nicht auf Instanzvariablen zugreifen?
18. Was unterscheidet eine abstrakte Klasse von einer Schnittstelle (Interface)? Warum kann eine Klasse mehrere Interfaces implementieren, aber nur von einer Klasse erben?
19. Ordne die Modifikatoren `public`, `protected`, `private` und „kein Modifikator“ nach ihrer Sichtbarkeit, von „überall sichtbar“ bis „nur in der eigenen Klasse“.
20. Warum kompiliert `Figur f = new Figur();` nicht, wenn `Figur` abstrakt ist? Warum ist `Figur f = new KreisF(2);` dagegen erlaubt?

---

## Teil B: Was gibt das Programm aus?

Erst auf Papier lösen, dann (wenn du willst) ausprobieren.

**B1**
```java
int i = 0;
while (i < 3) { System.out.print(i + " "); i++; }
do { System.out.print(i + " "); i++; } while (i < 3);
```

**B2**
```java
int zahl = 4;
switch (zahl) {
    case 3: System.out.print("drei ");
    case 4: System.out.print("vier ");
    case 5: System.out.print("fuenf ");
    default: System.out.print("ende");
}
```

**B3**
```java
System.out.println(1 + 2 + "3" + 4 + 5);
```

**B4**
```java
int x = 7 / 2;
double y = 7 / 2;
double z = 7 / 2.0;
System.out.println(x + " " + y + " " + z);
```

**B5**
```java
class Z {
    static int n = 0;
    Z() { n++; }
}
// in main:
new Z(); new Z(); Z zz = new Z();
System.out.println(Z.n + " " + zz.n);
```

**B6** (Kreis und Zylinder wie in Modul 7)
```java
Kreis k = new Zylinder(1, 2);
System.out.println(k.getClass().getSimpleName());
```

**B7**
```java
int a = 10, b = 3;
System.out.println((a > b ? a % b : b % a) + " " + (a++ * 2) + " " + a);
```

---

## Teil C: Fehler finden

Jedes Stück enthält **einen** Fehler, der das Kompilieren verhindert. Finde ihn und erkläre ihn.

**C1**
```java
public class Hallo {
    public static void main(String[] args) {
        int zahl = 5
        System.out.println(zahl);
    }
}
```

**C2**
```java
class Rad {
    private String farbe;
    Rad(String farbe) { this.farbe = farbe; }
}
// in main:
Rad r = new Rad();
```

**C3**
```java
class Zaehler {
    int wert;
    static void erhoehe() { wert++; }
}
```

**C4**
```java
interface Bewegung { void moveX(int m); }
class Puck implements Bewegung {
    void moveX(int m) { }
}
```

**C5**
```java
boolean fertig = 1;
```

---

## Teil D: Praxis – ein eigenes Paket (Skript S. 17/18)

Baue das Beispiel aus dem Skript selbst nach:

1. Lege einen neuen Ordner `paketuebung` an. Lege darin den Unterordner `MeinPak` an.
2. Schreibe in `MeinPak/Komma.java` eine public-Klasse `Komma` mit der Methode `komma()`, die `" Komma | "` ausgibt. Erste Zeile: `package MeinPak;`
3. Schreibe in `MeinPak/Strich.java` genauso eine Klasse `Strich` mit der Methode `strich()`, die `" Strich - "` ausgibt.
4. Schreibe im Ordner `paketuebung` die Klasse `PaketTest`. Sie importiert mit `import MeinPak.*;` beide Klassen und ruft beide Methoden auf.
5. Übersetze und starte das Programm im Ordner `paketuebung`:
   ```
   javac PaketTest.java
   java PaketTest
   ```
6. Schau nach, welche `.class`-Dateien entstanden sind und in welchen Ordnern.

Zusatzfrage: Was passiert, wenn du in `Komma.java` das Wort `public` vor `class` weglässt?

Eine Musterlösung findest du in `loesungen/modul10_pakete/`.
