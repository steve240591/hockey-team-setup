/*
 * MODUL 6 - Datenkapselung, Konstruktoren, this, Überladen
 * Passend zum Skript: Lektion 9 (Seiten 28-30), Beispiel Fahrrad3/Fahrrad4
 *
 * Alle Aufgaben stehen diesmal in den Klassen KaderSpieler und Spielstand
 * unten in der Datei. Die Instanzvariablen sind private - von außen kommt
 * man nur noch über Methoden an die Daten (Prinzip der Datenkapselung).
 *
 * Start:  java Modul06_Kapselung.java
 */
public class Modul06_Kapselung {

    public static void main(String[] args) {
        System.out.println("=== Modul 6: Datenkapselung und Konstruktoren ===");

        abschnitt("Aufgabe 1 - Standardkonstruktor und Getter");
        pruefe("Name", "Unbekannt", () -> new KaderSpieler().getName());
        pruefe("Nummer", 0, () -> new KaderSpieler().getNummer());
        pruefe("Tore", 0, () -> new KaderSpieler().getTore());

        abschnitt("Aufgabe 2 - Konstruktor mit Parametern");
        pruefe("Name", "Draisaitl", () -> new KaderSpieler("Draisaitl", 29).getName());
        pruefe("Nummer", 29, () -> new KaderSpieler("Draisaitl", 29).getNummer());
        pruefe("Tore", 0, () -> new KaderSpieler("Draisaitl", 29).getTore());

        abschnitt("Aufgabe 3 - Kopierkonstruktor");
        pruefe("Kopie hat gleiche Werte", "Seider #53 (2 Tore)", () -> {
            KaderSpieler original = new KaderSpieler("Seider", 53);
            original.torErzielen();
            original.torErzielen();
            return new KaderSpieler(original).toString();
        });
        pruefe("Kopie ist ein eigenes Objekt", 2, () -> {
            KaderSpieler original = new KaderSpieler("Seider", 53);
            original.torErzielen();
            original.torErzielen();
            KaderSpieler kopie = new KaderSpieler(original);
            kopie.torErzielen(); // darf das Original NICHT verändern
            return original.getTore();
        });

        abschnitt("Aufgabe 4 - setNummer mit Pruefung");
        pruefe("gueltige Nummer -> true", true, () -> new KaderSpieler().setNummer(17));
        pruefe("gueltige Nummer wird gespeichert", 17, () -> {
            KaderSpieler s = new KaderSpieler();
            s.setNummer(17);
            return s.getNummer();
        });
        pruefe("Nummer 100 -> false", false, () -> new KaderSpieler().setNummer(100));
        pruefe("Nummer 0 -> false", false, () -> new KaderSpieler().setNummer(0));
        pruefe("ungueltige Nummer aendert nichts", 29, () -> {
            KaderSpieler s = new KaderSpieler("Draisaitl", 29);
            s.setNummer(-5);
            return s.getNummer();
        });

        abschnitt("Aufgabe 5 - torErzielen ueberladen");
        pruefe("torErzielen()", 1, () -> {
            KaderSpieler s = new KaderSpieler();
            s.torErzielen();
            return s.getTore();
        });
        pruefe("torErzielen(3)", 3, () -> {
            KaderSpieler s = new KaderSpieler();
            s.torErzielen(3);
            return s.getTore();
        });
        pruefe("torErzielen(-2) wird ignoriert", 1, () -> {
            KaderSpieler s = new KaderSpieler();
            s.torErzielen();
            s.torErzielen(-2);
            return s.getTore();
        });

        abschnitt("Aufgabe 6 - toString");
        pruefe("toString()", "Draisaitl #29 (0 Tore)",
                () -> new KaderSpieler("Draisaitl", 29).toString());

        abschnitt("Aufgabe 7 - Spielstand");
        pruefe("Anzeige zu Beginn", "Adler 0:0 Eisbaeren",
                () -> new Spielstand("Adler", "Eisbaeren").anzeige());
        pruefe("Anzeige nach Toren", "Adler 2:1 Eisbaeren", () -> {
            Spielstand s = new Spielstand("Adler", "Eisbaeren");
            s.torHeim();
            s.torGast();
            s.torHeim();
            return s.anzeige();
        });
        pruefe("fuehrend: Heim", "Adler", () -> {
            Spielstand s = new Spielstand("Adler", "Eisbaeren");
            s.torHeim();
            return s.fuehrend();
        });
        pruefe("fuehrend: Gast", "Eisbaeren", () -> {
            Spielstand s = new Spielstand("Adler", "Eisbaeren");
            s.torGast();
            return s.fuehrend();
        });
        pruefe("fuehrend: unentschieden", "unentschieden",
                () -> new Spielstand("Adler", "Eisbaeren").fuehrend());

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

class KaderSpieler {
    private String name;
    private int nummer;
    private int tore;

    // Aufgabe 1: Standardkonstruktor. Startwerte: name "Unbekannt", nummer 0, tore 0.
    // Schreibe außerdem die drei Getter getName(), getNummer() und getTore().
    KaderSpieler() {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 2: Konstruktor mit Parametern. Achtung: Parameter und
    // Instanzvariable heißen gleich - dafür brauchst du this (Skript S. 29).
    KaderSpieler(String name, int nummer) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 3: Kopierkonstruktor (wie Fahrrad4(Fahrrad4 f) im Skript S. 30).
    // Übernimm alle Werte von s. Tipp: this(...) ruft einen anderen Konstruktor auf.
    KaderSpieler(KaderSpieler s) {
        throw new UnsupportedOperationException("TODO");
    }

    String getName() {
        throw new UnsupportedOperationException("TODO");
    }

    int getNummer() {
        throw new UnsupportedOperationException("TODO");
    }

    int getTore() {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 4: Setter mit Prüfung - ein Vorteil der Datenkapselung!
    // Nur Nummern von 1 bis 99 sind erlaubt. Gültig: speichern und true
    // zurückgeben. Ungültig: nichts ändern und false zurückgeben.
    boolean setNummer(int nummer) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 5: Überladen (Skript S. 30). Zwei Methoden mit gleichem Namen:
    //   torErzielen()           -> ein Tor mehr
    //   torErzielen(int anzahl) -> anzahl Tore mehr (negative Werte ignorieren)
    void torErzielen() {
        throw new UnsupportedOperationException("TODO");
    }

    void torErzielen(int anzahl) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 6: toString() überschreibt die Methode aus der Klasse Object
    // (Skript S. 16/17). Format: "Draisaitl #29 (0 Tore)"
    @Override
    public String toString() {
        throw new UnsupportedOperationException("TODO");
    }
}

// Aufgabe 7: Eine eigene Klasse mit privaten Daten.
// Ein Spielstand kennt die Namen beider Teams und die Tore.
//   anzeige()  -> "Adler 2:1 Eisbaeren"
//   fuehrend() -> Name des führenden Teams oder "unentschieden"
class Spielstand {
    // TODO: private Instanzvariablen anlegen

    Spielstand(String heim, String gast) {
        throw new UnsupportedOperationException("TODO");
    }

    void torHeim() {
        throw new UnsupportedOperationException("TODO");
    }

    void torGast() {
        throw new UnsupportedOperationException("TODO");
    }

    String anzeige() {
        throw new UnsupportedOperationException("TODO");
    }

    String fuehrend() {
        throw new UnsupportedOperationException("TODO");
    }
}
