/*
 * MODUL 7 - Vererbung, Überschreiben, super, dynamische Bindung
 * Passend zum Skript: Lektion 10 (Seiten 31-35), Beispiel Kreis/Zylinder
 *
 * Hinweis: Das Skript rechnet mit 3.14. Wir nehmen die genauere
 * Konstante Math.PI aus der Klasse Math (Skript S. 37).
 *
 * MUSTERLÖSUNG - erst anschauen, wenn du es selbst versucht hast!
 */
public class Modul07_Vererbung {

    // ------------------------------------------------------------------
    // Aufgabe 4: Dynamische Bindung (Skript S. 34/35).
    // Das Feld enthält Kreise UND Zylinder. Addiere alle flaeche()-Werte.
    // Für Zylinder wird automatisch die überschriebene Methode genommen!
    // ------------------------------------------------------------------
    static double gesamtFlaeche(Kreis[] formen) {
        double summe = 0;
        for (Kreis k : formen) {
            summe += k.flaeche();
        }
        return summe;
    }

    // ------------------------------------------------------------------
    // Aufgabe 5: Typprüfung und Typkonvertierung (Skript S. 35).
    // Addiere die Höhen aller Zylinder im Feld. Normale Kreise ignorieren.
    // Tipp:  if (k instanceof Zylinder)  und  ((Zylinder) k).getH()
    // ------------------------------------------------------------------
    static double summeHoehen(Kreis[] formen) {
        double summe = 0;
        for (Kreis k : formen) {
            if (k instanceof Zylinder) {
                summe += ((Zylinder) k).getH();
            }
        }
        return summe;
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    static Kreis[] beispielFormen() {
        return new Kreis[] {new Kreis(1), new Zylinder(1, 1), new Kreis(2), new Zylinder(1, 3)};
    }

    public static void main(String[] args) {
        System.out.println("=== Modul 7: Vererbung ===");

        abschnitt("Aufgabe 1 - Kreis");
        pruefe("new Kreis(1).flaeche()", Math.PI, () -> new Kreis(1).flaeche());
        pruefe("new Kreis(2).flaeche()", 4 * Math.PI, () -> new Kreis(2).flaeche());
        pruefe("new Kreis(1).umfang()", 2 * Math.PI, () -> new Kreis(1).umfang());

        abschnitt("Aufgabe 2 - Zylinder: Konstruktoren und setH");
        pruefe("new Zylinder() hat Radius 1", 1.0, () -> new Zylinder().getRad());
        pruefe("new Zylinder() hat Hoehe 1", 1.0, () -> new Zylinder().getH());
        pruefe("new Zylinder(2, 5) hat Radius 2", 2.0, () -> new Zylinder(2, 5).getRad());
        pruefe("new Zylinder(2, 5) hat Hoehe 5", 5.0, () -> new Zylinder(2, 5).getH());
        pruefe("setH(4) liefert 4", 4.0, () -> new Zylinder().setH(4));
        pruefe("Zylinder erbt setRad()", 3.0, () -> new Zylinder().setRad(3));

        abschnitt("Aufgabe 3 - flaeche() ueberschreiben, volumen()");
        pruefe("Zylinder(2, 5).flaeche() = Oberflaeche", 28 * Math.PI,
                () -> new Zylinder(2, 5).flaeche());
        pruefe("Zylinder().flaeche()", 4 * Math.PI, () -> new Zylinder().flaeche());
        pruefe("Zylinder(2, 5).volumen()", 20 * Math.PI, () -> new Zylinder(2, 5).volumen());
        pruefe("Kreis-Referenz auf Zylinder", 28 * Math.PI, () -> {
            Kreis k = new Zylinder(2, 5); // Objekt vom Typ Kreis, Instanz von Zylinder
            return k.flaeche();
        });

        abschnitt("Aufgabe 4 - gesamtFlaeche");
        pruefe("gesamtFlaeche(Kreis, Zylinder, Kreis, Zylinder)",
                Math.PI + 4 * Math.PI + 4 * Math.PI + 8 * Math.PI, () -> gesamtFlaeche(beispielFormen()));
        pruefe("gesamtFlaeche(leeres Feld)", 0.0, () -> gesamtFlaeche(new Kreis[0]));

        abschnitt("Aufgabe 5 - summeHoehen");
        pruefe("summeHoehen(...)", 4.0, () -> summeHoehen(beispielFormen()));

        abschnitt("Aufgabe 6 - Person und Trainer");
        pruefe("Person.vorstellen()", "Ich bin Kim", () -> new Person("Kim").vorstellen());
        pruefe("Trainer.vorstellen()", "Ich bin Pat, Trainer von Adler Mannheim",
                () -> new Trainer("Pat", "Adler Mannheim").vorstellen());
        pruefe("Trainer erbt getName()", "Pat", () -> new Trainer("Pat", "Adler").getName());
        pruefe("dynamische Bindung", "Ich bin Pat, Trainer von Adler", () -> {
            Person p = new Trainer("Pat", "Adler");
            return p.vorstellen();
        });

        zusammenfassung();
    }

    // =====================================================================
    //  AUTOMATISCHER PRUEFER - ab hier musst du nichts veraendern.
    //  (Reinschauen ist aber erlaubt.)
    // =====================================================================

    /** Ein Stueck Code, das einen Wert berechnet. */
    interface Berechnung {
        Object berechne() throws Exception;
    }

    private static int bestanden = 0;
    private static int gesamt = 0;
    private static int offen = 0;

    static void abschnitt(String titel) {
        System.out.println();
        System.out.println(titel);
    }

    static void pruefe(String beschreibung, Object erwartet, Berechnung code) {
        gesamt++;
        Object ergebnis;
        try {
            ergebnis = code.berechne();
        } catch (Throwable t) {
            if (t instanceof UnsupportedOperationException && "TODO".equals(t.getMessage())) {
                offen++;
                System.out.println("  [OFFEN]   " + beschreibung);
            } else {
                System.out.println("  [ABSTURZ] " + beschreibung);
                System.out.println("            " + t);
            }
            return;
        }
        if (gleich(erwartet, ergebnis)) {
            bestanden++;
            System.out.println("  [OK]      " + beschreibung);
        } else {
            System.out.println("  [FEHLER]  " + beschreibung);
            System.out.println("            erwartet: " + alsText(erwartet));
            System.out.println("            erhalten: " + alsText(ergebnis));
        }
    }

    private static boolean gleich(Object a, Object b) {
        if (a instanceof Double x && b instanceof Double y) {
            return Math.abs(x - y) <= 1e-9 * Math.max(1.0, Math.abs(x));
        }
        return java.util.Arrays.deepEquals(new Object[] {a}, new Object[] {b});
    }

    private static String alsText(Object o) {
        if (o instanceof String s) {
            return "\"" + s + "\"";
        }
        if (o instanceof Character c) {
            return "'" + c + "'";
        }
        String text = java.util.Arrays.deepToString(new Object[] {o});
        return text.substring(1, text.length() - 1);
    }

    static void zusammenfassung() {
        System.out.println();
        System.out.println("--------------------------------------------------");
        System.out.println("Bestanden: " + bestanden + " von " + gesamt
                + (offen > 0 ? "   (noch offen: " + offen + ")" : ""));
        if (bestanden == gesamt) {
            System.out.println("Alles richtig - weiter zum naechsten Modul!");
        }
    }
}

// ----------------------------------------------------------------------
// Basisklasse Kreis (wie im Skript S. 32). r ist protected, damit auch
// Subklassen darauf zugreifen können.
// ----------------------------------------------------------------------
class Kreis {
    protected double r;

    Kreis() {
        this.r = 1.0;
    }

    Kreis(double r) {
        this.r = r;
    }

    double setRad(double r) {
        this.r = r;
        return r;
    }

    double getRad() {
        return r;
    }

    // Aufgabe 1: Fläche (PI * r * r) und Umfang (2 * PI * r)
    double flaeche() {
        return Math.PI * r * r;
    }

    double umfang() {
        return 2 * Math.PI * r;
    }
}

// ----------------------------------------------------------------------
// Aufgabe 2 und 3: Zylinder erbt von Kreis ("Zylinder sind Kreise mit einer Höhe").
// ----------------------------------------------------------------------
class Zylinder extends Kreis {
    protected double h;

    // Aufgabe 2a: Standardkonstruktor - Radius 1 (über super()) und Höhe 1
    Zylinder() {
        super();
        this.h = 1.0;
    }

    // Aufgabe 2b: Konstruktor mit Radius und Höhe.
    // Den Radius übergibst du mit super(r) an den Konstruktor von Kreis.
    Zylinder(double r, double h) {
        super(r);
        this.h = h;
    }

    // Aufgabe 2c: Höhe setzen und zurückgeben (wie setRad in Kreis)
    double setH(double h) {
        this.h = h;
        return h;
    }

    double getH() {
        return h;
    }

    // Aufgabe 3a: flaeche() ÜBERSCHREIBEN - liefert jetzt die Oberfläche:
    //   2 * Grundfläche + h * Umfang      (Skript S. 33, Zylinder2)
    // Grundfläche und Umfang bekommst du mit super.flaeche() und super.umfang().
    @Override
    double flaeche() {
        return 2 * super.flaeche() + h * super.umfang();
    }

    // Aufgabe 3b: Volumen = Grundfläche * h
    // Falle: Warum ist  flaeche() * h  hier falsch?
    double volumen() {
        return super.flaeche() * h; // flaeche() wäre die ÜBERSCHRIEBENE Methode (Oberfläche)
    }
}

// ----------------------------------------------------------------------
// Aufgabe 6: super.methode() außerhalb der Mathematik (vgl. Verkehrsrad, S. 31).
// Person ist fertig. Trainer erbt von Person und hat zusätzlich ein Team.
//   new Trainer("Pat", "Adler").vorstellen() -> "Ich bin Pat, Trainer von Adler"
// Nutze in Trainer.vorstellen() unbedingt super.vorstellen()!
// ----------------------------------------------------------------------
class Person {
    private String name;

    Person(String name) {
        this.name = name;
    }

    String getName() {
        return name;
    }

    String vorstellen() {
        return "Ich bin " + name;
    }
}

class Trainer extends Person {
    private String team;

    Trainer(String name, String team) {
        super(name);
        this.team = team;
    }

    @Override
    String vorstellen() {
        return super.vorstellen() + ", Trainer von " + team;
    }
}
