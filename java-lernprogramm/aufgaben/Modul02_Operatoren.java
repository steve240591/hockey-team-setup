/*
 * MODUL 2 - Operatoren und Ausdrücke
 * Passend zum Skript: Lektion 7, Operatoren und Ausdrücke (Seiten 20-21)
 *
 * Start:  java Modul02_Operatoren.java
 *
 * Teil A: Methoden schreiben.
 * Teil B: "Vorhersagen" - hier schreibst du KEINEN Algorithmus, sondern
 *         überlegst auf Papier, welchen Wert ein Ausdruck hat, und gibst
 *         deinen Tipp mit return zurück. Erst denken, dann testen!
 */
public class Modul02_Operatoren {

    // ==================================================================
    //  Teil A
    // ==================================================================

    // Aufgabe 1: Ist die Zahl gerade? (Restwert-Operator %)
    // Beispiel: 4 -> true    7 -> false    -4 -> true
    static boolean istGerade(int zahl) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 2: Schaltjahr? Nutze nur logische Operatoren, KEIN if.
    // Regel: durch 4 teilbar, aber nicht durch 100 - außer es ist durch 400 teilbar.
    // Beispiel: 2024 -> true   2023 -> false   1900 -> false   2000 -> true
    static boolean istSchaltjahr(int jahr) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 3: Betrag einer Zahl mit dem Konditionaloperator  a ? b : c
    // Beispiel: -5 -> 5    7 -> 7    0 -> 0
    static int betrag(int zahl) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 4: Größte von drei Zahlen - nur mit dem Konditionaloperator.
    // Beispiel: (5, 9, 2) -> 9
    static int maximum(int a, int b, int c) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 5: Liegt x im Bereich von min bis max (beide eingeschlossen)?
    // Beispiel: (5, 1, 10) -> true    (10, 1, 10) -> true    (0, 1, 10) -> false
    static boolean imBereich(int x, int min, int max) {
        throw new UnsupportedOperationException("TODO");
    }

    // Aufgabe 6: Bitoperatoren (Skript S. 20)
    // a) x mit 2 hoch n multiplizieren - nur mit dem Schiebe-Operator <<
    //    Beispiel: (3, 2) -> 12
    // b) Ist in "zahl" das Bit an Stelle "position" gesetzt? (Stelle 0 = ganz rechts)
    //    Beispiel: 5 ist binär 101 -> Stelle 0: true, Stelle 1: false, Stelle 2: true
    //    Tipp: Schiebe nach rechts (>>) und verknüpfe mit & 1.
    static int malZweiHoch(int x, int n) {
        throw new UnsupportedOperationException("TODO");
    }

    static boolean istBitGesetzt(int zahl, int position) {
        throw new UnsupportedOperationException("TODO");
    }

    // ==================================================================
    //  Teil B: Vorhersagen - ersetze die throw-Zeile durch  return <dein Tipp>;
    // ==================================================================

    // Vorhersage 1 (Inkrement Post- und Prä-Notation):
    //     int a = 5;
    //     int b = a++ + ++a;
    // Welchen Wert hat b?
    static int vorhersage1() {
        throw new UnsupportedOperationException("TODO");
    }

    // Vorhersage 2 (Zuweisungsoperatoren):
    //     int x = 17;
    //     x %= 5;
    //     x *= 3;
    // Welchen Wert hat x?
    static int vorhersage2() {
        throw new UnsupportedOperationException("TODO");
    }

    // Vorhersage 3 (Stringverkettung):
    //     String s = "Ergebnis: " + 2 + 3;
    // Welchen Wert hat s?
    static String vorhersage3() {
        throw new UnsupportedOperationException("TODO");
    }

    // Vorhersage 4 (Short-Cut-Operator &&):
    //     int z = 0;
    //     boolean ok = (z != 0) && (10 / z > 1);
    // Welchen Wert hat ok? Und: Was würde mit & statt && passieren?
    static boolean vorhersage4() {
        throw new UnsupportedOperationException("TODO");
    }

    // Vorhersage 5 (Bitoperator UND):
    //     int i = 12 & 10;
    // Welchen Wert hat i?
    static int vorhersage5() {
        throw new UnsupportedOperationException("TODO");
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 2: Operatoren und Ausdruecke ===");

        abschnitt("Aufgabe 1 - istGerade");
        pruefe("istGerade(4)", true, () -> istGerade(4));
        pruefe("istGerade(7)", false, () -> istGerade(7));
        pruefe("istGerade(-4)", true, () -> istGerade(-4));
        pruefe("istGerade(0)", true, () -> istGerade(0));

        abschnitt("Aufgabe 2 - istSchaltjahr");
        pruefe("istSchaltjahr(2024)", true, () -> istSchaltjahr(2024));
        pruefe("istSchaltjahr(2023)", false, () -> istSchaltjahr(2023));
        pruefe("istSchaltjahr(1900)", false, () -> istSchaltjahr(1900));
        pruefe("istSchaltjahr(2000)", true, () -> istSchaltjahr(2000));

        abschnitt("Aufgabe 3 - betrag");
        pruefe("betrag(-5)", 5, () -> betrag(-5));
        pruefe("betrag(7)", 7, () -> betrag(7));
        pruefe("betrag(0)", 0, () -> betrag(0));

        abschnitt("Aufgabe 4 - maximum");
        pruefe("maximum(5, 9, 2)", 9, () -> maximum(5, 9, 2));
        pruefe("maximum(9, 5, 2)", 9, () -> maximum(9, 5, 2));
        pruefe("maximum(2, 5, 9)", 9, () -> maximum(2, 5, 9));
        pruefe("maximum(-1, -5, -3)", -1, () -> maximum(-1, -5, -3));

        abschnitt("Aufgabe 5 - imBereich");
        pruefe("imBereich(5, 1, 10)", true, () -> imBereich(5, 1, 10));
        pruefe("imBereich(10, 1, 10)", true, () -> imBereich(10, 1, 10));
        pruefe("imBereich(0, 1, 10)", false, () -> imBereich(0, 1, 10));
        pruefe("imBereich(11, 1, 10)", false, () -> imBereich(11, 1, 10));

        abschnitt("Aufgabe 6 - Bitoperatoren");
        pruefe("malZweiHoch(3, 2)", 12, () -> malZweiHoch(3, 2));
        pruefe("malZweiHoch(1, 10)", 1024, () -> malZweiHoch(1, 10));
        pruefe("istBitGesetzt(5, 0)", true, () -> istBitGesetzt(5, 0));
        pruefe("istBitGesetzt(5, 1)", false, () -> istBitGesetzt(5, 1));
        pruefe("istBitGesetzt(5, 2)", true, () -> istBitGesetzt(5, 2));

        // Nicht spicken: Hier rechnet Java die Ausdrücke wirklich aus.
        abschnitt("Teil B - Vorhersagen");
        int a = 5;
        int b = a++ + ++a;
        pruefe("Vorhersage 1", b, () -> vorhersage1());
        int x = 17;
        x %= 5;
        x *= 3;
        int xWert = x;
        pruefe("Vorhersage 2", xWert, () -> vorhersage2());
        pruefe("Vorhersage 3", "Ergebnis: " + 2 + 3, () -> vorhersage3());
        int z = 0;
        boolean ok = (z != 0) && (10 / z > 1);
        pruefe("Vorhersage 4", ok, () -> vorhersage4());
        pruefe("Vorhersage 5", 12 & 10, () -> vorhersage5());

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
