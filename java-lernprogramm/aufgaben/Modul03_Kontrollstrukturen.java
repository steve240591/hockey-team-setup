/*
 * MODUL 3 - Kontrollstrukturen
 * Passend zum Skript: Lektion 7, Kontrollstrukturen (Seiten 21-23)
 * if/else, switch (klassisch und mit ->), for, while, do-while,
 * break, continue und Marken.
 *
 * Start:  java Modul03_Kontrollstrukturen.java
 */
public class Modul03_Kontrollstrukturen {

    // ------------------------------------------------------------------
    // Aufgabe 1: Schulnote in Text umwandeln - mit der KLASSISCHEN
    // switch-Anweisung (case ... : ... break;).
    // 1 "sehr gut", 2 "gut", 3 "befriedigend", 4 "ausreichend",
    // 5 "mangelhaft", 6 "ungenuegend", sonst "keine Note"
    // Frage: Was passiert, wenn du ein break vergisst?
    // ------------------------------------------------------------------
    static String notenText(int note) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 2: switch als Ausdruck mit -> (Skript S. 22/23).
    // "Samstag", "Sonntag"                                   -> "Wochenende"
    // "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag" -> "Werktag"
    // alles andere                                           -> "unbekannt"
    // Tipp: case "Samstag", "Sonntag" -> "Wochenende";
    // ------------------------------------------------------------------
    static String tagesart(String tag) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 3: Summe 1 + 2 + ... + n mit einer for-Schleife.
    // Beispiel: 4 -> 10     100 -> 5050     0 -> 0
    // ------------------------------------------------------------------
    static int summeBis(int n) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 4: Fakultät n! = 1 * 2 * ... * n   (0! = 1)
    // Beispiel: 5 -> 120     20 -> 2432902008176640000
    // Frage: Warum ist der Rückgabetyp long und nicht int?
    // ------------------------------------------------------------------
    static long fakultaet(int n) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 5: Ist n eine Primzahl? (nur durch 1 und sich selbst teilbar,
    // 0 und 1 sind KEINE Primzahlen)
    // Beispiel: 2 -> true   17 -> true   21 -> false   1 -> false
    // Tipp: Sobald du einen Teiler findest, kannst du aufhören.
    // ------------------------------------------------------------------
    static boolean istPrimzahl(int n) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 6: Anzahl der Ziffern einer Zahl - mit einer do-while-Schleife.
    // Beispiel: 12345 -> 5     7 -> 1     0 -> 1     -42 -> 2
    // Frage: Warum passt do-while hier besser als while? (Denk an die 0!)
    // ------------------------------------------------------------------
    static int anzahlStellen(int zahl) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 7: Summe von 1 bis n, aber alle Vielfachen von 3 überspringen.
    // Benutze continue.
    // Beispiel: 10 -> 1+2+4+5+7+8+10 = 37
    // ------------------------------------------------------------------
    static int summeOhneDreier(int n) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 8: FizzBuzz. Zahlen 1 bis n, getrennt durch je EIN Leerzeichen.
    // Vielfache von 3 -> "Fizz", von 5 -> "Buzz", von 3 und 5 -> "FizzBuzz".
    // Beispiel: 5  -> "1 2 Fizz 4 Buzz"
    //           15 -> "1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz"
    // Achtung: Am Ende darf kein Leerzeichen stehen.
    // ------------------------------------------------------------------
    static String fizzBuzz(int n) {
        throw new UnsupportedOperationException("TODO");
    }

    // ------------------------------------------------------------------
    // Aufgabe 9: Marken und break (Skript S. 23).
    // Suche mit zwei verschachtelten Schleifen (i von 1 bis 9, j von i bis 9)
    // das ERSTE Paar mit i * j == ziel und gib es als "i*j" zurück.
    // Gibt es keins, gib "keins" zurück.
    // Beispiel: 12 -> "2*6"     81 -> "9*9"     11 -> "keins"
    // Tipp: Mit  aussen: for (...)  und  break aussen;  verlässt du beide Schleifen.
    // ------------------------------------------------------------------
    static String erstesPaar(int ziel) {
        throw new UnsupportedOperationException("TODO");
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 3: Kontrollstrukturen ===");

        abschnitt("Aufgabe 1 - notenText");
        pruefe("notenText(1)", "sehr gut", () -> notenText(1));
        pruefe("notenText(3)", "befriedigend", () -> notenText(3));
        pruefe("notenText(6)", "ungenuegend", () -> notenText(6));
        pruefe("notenText(9)", "keine Note", () -> notenText(9));

        abschnitt("Aufgabe 2 - tagesart");
        pruefe("tagesart(\"Sonntag\")", "Wochenende", () -> tagesart("Sonntag"));
        pruefe("tagesart(\"Mittwoch\")", "Werktag", () -> tagesart("Mittwoch"));
        pruefe("tagesart(\"Feiertag\")", "unbekannt", () -> tagesart("Feiertag"));

        abschnitt("Aufgabe 3 - summeBis");
        pruefe("summeBis(4)", 10, () -> summeBis(4));
        pruefe("summeBis(100)", 5050, () -> summeBis(100));
        pruefe("summeBis(0)", 0, () -> summeBis(0));

        abschnitt("Aufgabe 4 - fakultaet");
        pruefe("fakultaet(0)", 1L, () -> fakultaet(0));
        pruefe("fakultaet(5)", 120L, () -> fakultaet(5));
        pruefe("fakultaet(20)", 2432902008176640000L, () -> fakultaet(20));

        abschnitt("Aufgabe 5 - istPrimzahl");
        pruefe("istPrimzahl(2)", true, () -> istPrimzahl(2));
        pruefe("istPrimzahl(17)", true, () -> istPrimzahl(17));
        pruefe("istPrimzahl(21)", false, () -> istPrimzahl(21));
        pruefe("istPrimzahl(1)", false, () -> istPrimzahl(1));
        pruefe("istPrimzahl(97)", true, () -> istPrimzahl(97));
        pruefe("istPrimzahl(49)", false, () -> istPrimzahl(49));

        abschnitt("Aufgabe 6 - anzahlStellen");
        pruefe("anzahlStellen(12345)", 5, () -> anzahlStellen(12345));
        pruefe("anzahlStellen(7)", 1, () -> anzahlStellen(7));
        pruefe("anzahlStellen(0)", 1, () -> anzahlStellen(0));
        pruefe("anzahlStellen(-42)", 2, () -> anzahlStellen(-42));

        abschnitt("Aufgabe 7 - summeOhneDreier");
        pruefe("summeOhneDreier(10)", 37, () -> summeOhneDreier(10));
        pruefe("summeOhneDreier(2)", 3, () -> summeOhneDreier(2));

        abschnitt("Aufgabe 8 - fizzBuzz");
        pruefe("fizzBuzz(5)", "1 2 Fizz 4 Buzz", () -> fizzBuzz(5));
        pruefe("fizzBuzz(15)", "1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz",
                () -> fizzBuzz(15));
        pruefe("fizzBuzz(1)", "1", () -> fizzBuzz(1));

        abschnitt("Aufgabe 9 - erstesPaar");
        pruefe("erstesPaar(12)", "2*6", () -> erstesPaar(12));
        pruefe("erstesPaar(81)", "9*9", () -> erstesPaar(81));
        pruefe("erstesPaar(7)", "1*7", () -> erstesPaar(7));
        pruefe("erstesPaar(11)", "keins", () -> erstesPaar(11));

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
