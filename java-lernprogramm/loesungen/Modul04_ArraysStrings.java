/*
 * MODUL 4 - Arrays (Felder) und Strings
 * Passend zum Skript: Strings (S. 13), Kommandozeilen-Parameter (S. 14/15),
 * for-Schleife über Felder (S. 22), Felder von Objekten (S. 35).
 *
 * Kurz zur Wiederholung:
 *   int[] zahlen = {4, 8, 15};    // Feld mit 3 Elementen anlegen
 *   zahlen.length                 // Länge des Feldes (ohne Klammern!)
 *   zahlen[0]                     // erstes Element, zahlen[zahlen.length - 1] das letzte
 *   int[] neu = new int[5];       // neues Feld mit 5 Nullen
 *   for (int z : zahlen) { ... }  // jedes Element durchlaufen
 *   text.length()                 // Länge eines Strings (mit Klammern!)
 *   text.charAt(i)                // Zeichen an Stelle i
 *   text.toLowerCase()            // alles in Kleinbuchstaben
 *
 * MUSTERLÖSUNG - erst anschauen, wenn du es selbst versucht hast!
 */
public class Modul04_ArraysStrings {

    // Aufgabe 1: Summe aller Elemente. Nutze die for-each-Schleife.
    // Beispiel: {1, 2, 3} -> 6     {} -> 0
    static int summe(int[] zahlen) {
        int summe = 0;
        for (int z : zahlen) {
            summe += z;
        }
        return summe;
    }

    // Aufgabe 2: Größtes Element (das Feld ist nie leer).
    // Beispiel: {3, 9, 4} -> 9     {-5, -2, -9} -> -2
    // Falle: Wenn du mit max = 0 startest, klappt das zweite Beispiel nicht.
    static int maximum(int[] zahlen) {
        int max = zahlen[0];
        for (int i = 1; i < zahlen.length; i++) {
            if (zahlen[i] > max) {
                max = zahlen[i];
            }
        }
        return max;
    }

    // Aufgabe 3: Wie oft kommt "gesucht" im Feld vor?
    // Beispiel: ({1, 2, 1, 1}, 1) -> 3
    static int zaehle(int[] zahlen, int gesucht) {
        int anzahl = 0;
        for (int z : zahlen) {
            if (z == gesucht) {
                anzahl++;
            }
        }
        return anzahl;
    }

    // Aufgabe 4: Ein NEUES Feld in umgekehrter Reihenfolge zurückgeben.
    // Das Original-Feld darf nicht verändert werden!
    // Beispiel: {1, 2, 3} -> {3, 2, 1}
    static int[] umkehren(int[] zahlen) {
        int[] ergebnis = new int[zahlen.length];
        for (int i = 0; i < zahlen.length; i++) {
            ergebnis[i] = zahlen[zahlen.length - 1 - i];
        }
        return ergebnis;
    }

    // Aufgabe 5: Vokale zählen (a, e, i, o, u - Groß- und Kleinschreibung egal).
    // Beispiel: "Eishockey" -> 4     "PUCK" -> 1     "" -> 0
    static int zaehleVokale(String text) {
        int anzahl = 0;
        String klein = text.toLowerCase();
        for (int i = 0; i < klein.length(); i++) {
            char c = klein.charAt(i);
            if (c == 'a' || c == 'e' || c == 'i' || c == 'o' || c == 'u') {
                anzahl++;
            }
        }
        return anzahl;
    }

    // Aufgabe 6: Palindrom? (vorwärts und rückwärts gleich, Groß/klein egal)
    // Beispiel: "Anna" -> true    "Otto" -> true    "Hockey" -> false
    // Tipp: Vergleiche das erste mit dem letzten Zeichen, das zweite mit dem
    //       vorletzten usw.
    static boolean istPalindrom(String wort) {
        String w = wort.toLowerCase();
        for (int i = 0; i < w.length() / 2; i++) {
            if (w.charAt(i) != w.charAt(w.length() - 1 - i)) {
                return false;
            }
        }
        return true;
    }

    // Aufgabe 7: Kommandozeilen-Parameter (vgl. Skript S. 15, Eingabe.java).
    // Verbinde alle Einträge mit "-".
    // Beispiel: {"abc", "123", "xyz"} -> "abc-123-xyz"     {} -> ""
    static String verbinde(String[] eingabe) {
        String ergebnis = "";
        for (int i = 0; i < eingabe.length; i++) {
            if (i > 0) {
                ergebnis += "-";
            }
            ergebnis += eingabe[i];
        }
        return ergebnis;
    }

    // Aufgabe 8 (Bonus): Zweidimensionales Feld. Bilde die Summe jeder Spalte.
    // Beispiel: {{1, 2, 3},
    //            {4, 5, 6}}  -> {5, 7, 9}
    // Tipp: matrix.length = Anzahl Zeilen, matrix[0].length = Anzahl Spalten
    static int[] spaltenSummen(int[][] matrix) {
        int[] summen = new int[matrix[0].length];
        for (int zeile = 0; zeile < matrix.length; zeile++) {
            for (int spalte = 0; spalte < matrix[zeile].length; spalte++) {
                summen[spalte] += matrix[zeile][spalte];
            }
        }
        return summen;
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 4: Arrays und Strings ===");

        abschnitt("Aufgabe 1 - summe");
        pruefe("summe({1, 2, 3})", 6, () -> summe(new int[] {1, 2, 3}));
        pruefe("summe({})", 0, () -> summe(new int[] {}));
        pruefe("summe({-4, 4, 10})", 10, () -> summe(new int[] {-4, 4, 10}));

        abschnitt("Aufgabe 2 - maximum");
        pruefe("maximum({3, 9, 4})", 9, () -> maximum(new int[] {3, 9, 4}));
        pruefe("maximum({-5, -2, -9})", -2, () -> maximum(new int[] {-5, -2, -9}));
        pruefe("maximum({7})", 7, () -> maximum(new int[] {7}));

        abschnitt("Aufgabe 3 - zaehle");
        pruefe("zaehle({1, 2, 1, 1}, 1)", 3, () -> zaehle(new int[] {1, 2, 1, 1}, 1));
        pruefe("zaehle({1, 2, 1, 1}, 5)", 0, () -> zaehle(new int[] {1, 2, 1, 1}, 5));

        abschnitt("Aufgabe 4 - umkehren");
        pruefe("umkehren({1, 2, 3})", new int[] {3, 2, 1}, () -> umkehren(new int[] {1, 2, 3}));
        pruefe("umkehren({})", new int[] {}, () -> umkehren(new int[] {}));
        pruefe("Original bleibt unveraendert", new int[] {1, 2, 3}, () -> {
            int[] original = {1, 2, 3};
            umkehren(original);
            return original;
        });

        abschnitt("Aufgabe 5 - zaehleVokale");
        pruefe("zaehleVokale(\"Eishockey\")", 4, () -> zaehleVokale("Eishockey"));
        pruefe("zaehleVokale(\"PUCK\")", 1, () -> zaehleVokale("PUCK"));
        pruefe("zaehleVokale(\"\")", 0, () -> zaehleVokale(""));

        abschnitt("Aufgabe 6 - istPalindrom");
        pruefe("istPalindrom(\"Anna\")", true, () -> istPalindrom("Anna"));
        pruefe("istPalindrom(\"Otto\")", true, () -> istPalindrom("Otto"));
        pruefe("istPalindrom(\"Hockey\")", false, () -> istPalindrom("Hockey"));
        pruefe("istPalindrom(\"Rentner\")", true, () -> istPalindrom("Rentner"));

        abschnitt("Aufgabe 7 - verbinde");
        pruefe("verbinde({\"abc\", \"123\", \"xyz\"})", "abc-123-xyz",
                () -> verbinde(new String[] {"abc", "123", "xyz"}));
        pruefe("verbinde({\"solo\"})", "solo", () -> verbinde(new String[] {"solo"}));
        pruefe("verbinde({})", "", () -> verbinde(new String[] {}));

        abschnitt("Aufgabe 8 (Bonus) - spaltenSummen");
        pruefe("spaltenSummen({{1,2,3},{4,5,6}})", new int[] {5, 7, 9},
                () -> spaltenSummen(new int[][] {{1, 2, 3}, {4, 5, 6}}));

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
