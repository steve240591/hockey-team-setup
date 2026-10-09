/*
 * MODUL 8 - Klassenvariablen, Klassenmethoden, Konstanten (static, final)
 * Passend zum Skript: Lektion 11 (Seiten 36-38), Beispiel Kreis3/Kreis4
 *
 * Merke:
 *   Instanzvariable  -> jedes Objekt hat seine EIGENE Kopie
 *   Klassenvariable  -> static, gibt es nur EINMAL für die ganze Klasse
 *   Konstante        -> static final, Name in GROSSBUCHSTABEN (Skript S. 9)
 *   Klassenmethode   -> static, Aufruf über den Klassennamen: Klasse.methode()
 *
 * Start:  java Modul08_Klassenvariablen.java
 */
public class Modul08_Klassenvariablen {

    // ------------------------------------------------------------------
    // Aufgabe 4 (Vorhersage): Klassenvariable oder Instanzvariable?
    // Die Klasse Zaehler steht unten. Was liefern die beiden Methoden nach:
    //     Zaehler a = new Zaehler();
    //     Zaehler b = new Zaehler();
    //     a.klick();
    //     a.klick();
    //     b.klick();
    // a) Zaehler.gesamt  = ?
    // b) b.eigen         = ?
    // ------------------------------------------------------------------
    static int vorhersageGesamt() {
        throw new UnsupportedOperationException("TODO");
    }

    static int vorhersageEigen() {
        throw new UnsupportedOperationException("TODO");
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 8: Klassenvariablen und Klassenmethoden ===");

        abschnitt("Aufgabe 1 - Puck zaehlt seine Instanzen");
        pruefe("zwei neue Pucks -> anzahl steigt um 2", 2, () -> {
            int vorher = Puck.getAnzahl();
            new Puck();
            new Puck();
            return Puck.getAnzahl() - vorher;
        });
        pruefe("Seriennummern sind fortlaufend", 1, () -> {
            Puck p1 = new Puck();
            Puck p2 = new Puck();
            return p2.getSeriennummer() - p1.getSeriennummer();
        });
        pruefe("Seriennummer = Anzahl beim Erzeugen", true, () -> {
            Puck p = new Puck();
            return p.getSeriennummer() == Puck.getAnzahl();
        });

        abschnitt("Aufgabe 2 - Konstanten und Klassenmethoden in Umrechner");
        pruefe("Umrechner.KMH_PRO_MS", 3.6, () -> Umrechner.KMH_PRO_MS);
        pruefe("Umrechner.kmhInMs(36)", 10.0, () -> Umrechner.kmhInMs(36));
        pruefe("Umrechner.msInKmh(10)", 36.0, () -> Umrechner.msInKmh(10));
        pruefe("Umrechner.kreisflaeche(2)", 4 * Math.PI, () -> Umrechner.kreisflaeche(2));

        abschnitt("Aufgabe 3 - Eisflaeche");
        pruefe("Eisflaeche.flaeche()", 1800.0, () -> Eisflaeche.flaeche());

        abschnitt("Aufgabe 4 - Vorhersage");
        Zaehler a = new Zaehler();
        Zaehler b = new Zaehler();
        a.klick();
        a.klick();
        b.klick();
        pruefe("a) Zaehler.gesamt", Zaehler.gesamt, () -> vorhersageGesamt());
        pruefe("b) b.eigen", b.eigen, () -> vorhersageEigen());

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
// Aufgabe 1: Jeder Puck bekommt eine fortlaufende Seriennummer.
//  - Die Klassenvariable anzahl zählt, wie viele Pucks erzeugt wurden.
//  - Sie wird in einem statischen Initialisierungsblock auf 0 gesetzt
//    (Skript S. 38, "statische Konstruktoren").
//  - Im Konstruktor: anzahl erhöhen, dann seriennummer = anzahl.
//  - getAnzahl() ist eine Klassenmethode.
// ----------------------------------------------------------------------
class Puck {
    private static int anzahl;
    private final int seriennummer;

    static {
        anzahl = 0;
    }

    Puck() {
        throw new UnsupportedOperationException("TODO");
    }

    int getSeriennummer() {
        throw new UnsupportedOperationException("TODO");
    }

    static int getAnzahl() {
        throw new UnsupportedOperationException("TODO");
    }
}

// ----------------------------------------------------------------------
// Aufgabe 2: Eine reine "Werkzeug-Klasse" (wie Math oder Kreis4 im Skript).
//  - Lege die Konstante  KMH_PRO_MS = 3.6  an (static final).
//  - kmhInMs: km/h -> m/s (durch 3.6 teilen), msInKmh: umgekehrt.
//  - kreisflaeche(r) wie Kreis4.flaeche() im Skript S. 37.
// ----------------------------------------------------------------------
class Umrechner {
    static final double KMH_PRO_MS = 0; // TODO: richtigen Wert eintragen

    static double kmhInMs(double kmh) {
        throw new UnsupportedOperationException("TODO");
    }

    static double msInKmh(double ms) {
        throw new UnsupportedOperationException("TODO");
    }

    static double kreisflaeche(double r) {
        throw new UnsupportedOperationException("TODO");
    }
}

// ----------------------------------------------------------------------
// Aufgabe 3: Eine Eishockeyfläche ist (vereinfacht) ein Rechteck von
// 60 m x 30 m. Lege die Konstanten LAENGE und BREITE an und berechne
// in der Klassenmethode flaeche() die Fläche.
// ----------------------------------------------------------------------
class Eisflaeche {
    // TODO: Konstanten LAENGE und BREITE anlegen

    static double flaeche() {
        throw new UnsupportedOperationException("TODO");
    }
}

// ----------------------------------------------------------------------
// Für Aufgabe 4 (vorgegeben, nicht verändern)
// ----------------------------------------------------------------------
class Zaehler {
    static int gesamt = 0;
    int eigen = 0;

    void klick() {
        gesamt++;
        eigen++;
    }
}
