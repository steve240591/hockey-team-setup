/*
 * MODUL 1 - Grunddatentypen, Variablen, Typkonvertierung, Strings
 * Passend zum Skript: Lektion 4, 5 und 7 (Seiten 8-19)
 *
 * MUSTERLÖSUNG - erst anschauen, wenn du es selbst versucht hast!
 */
public class Modul01_Datentypen {

    // ------------------------------------------------------------------
    // Aufgabe 1: Bruttopreis (vgl. Skript S. 16, ImportDemo.java)
    // Berechne aus dem Nettopreis den Bruttopreis mit 19 % Mehrwertsteuer.
    // Beispiel: 100.0 -> 119.0
    // ------------------------------------------------------------------
    static double bruttopreis(double netto) {
        return netto * 1.19;
    }

    // ------------------------------------------------------------------
    // Aufgabe 2: Celsius in Fahrenheit umrechnen.  F = C * 9 / 5 + 32
    // Beispiel: 100.0 -> 212.0    37.0 -> 98.6
    // Falle: Schreib zum Testen einmal  9 / 5 * celsius + 32.
    //        Warum ist das Ergebnis falsch? (Skript S. 20: Ganzzahldivision)
    // ------------------------------------------------------------------
    static double celsiusInFahrenheit(double celsius) {
        return celsius * 9.0 / 5.0 + 32.0;
    }

    // ------------------------------------------------------------------
    // Aufgabe 3: Minuten als Text. Nutze die Ganzzahldivision / und den
    // Restwert-Operator %.
    // Beispiel: 125 -> "2 h 5 min"     59 -> "0 h 59 min"
    // ------------------------------------------------------------------
    static String minutenAlsText(int minuten) {
        int stunden = minuten / 60;
        int rest = minuten % 60;
        return stunden + " h " + rest + " min";
    }

    // ------------------------------------------------------------------
    // Aufgabe 4: Durchschnitt von zwei ganzen Zahlen - als Kommazahl!
    // Beispiel: (3, 4) -> 3.5
    // Falle: (a + b) / 2 ist eine Ganzzahldivision. Wie verhinderst du das?
    // ------------------------------------------------------------------
    static double durchschnitt(int a, int b) {
        return (a + b) / 2.0;
    }

    // ------------------------------------------------------------------
    // Aufgabe 5: Kommazahl in int umwandeln (Cast-Operator, Skript S. 19/20).
    // Beispiel: 2.538 -> 2      -2.7 -> -2
    // Frage: Rundet der Cast oder schneidet er ab?
    // ------------------------------------------------------------------
    static int abschneiden(double wert) {
        return (int) wert;
    }

    // ------------------------------------------------------------------
    // Aufgabe 6: char und int (Skript S. 19: char wird automatisch zu int).
    // a) Liefere den Unicode-Wert eines Zeichens.     'A' -> 65
    // b) Liefere das nächste Zeichen im Zeichensatz.  'A' -> 'B'
    //    Tipp: c + 1 ist ein int. Du brauchst einen Cast zurück nach char.
    // ------------------------------------------------------------------
    static int zeichenCode(char c) {
        return c;
    }

    static char naechstesZeichen(char c) {
        return (char) (c + 1);
    }

    // ------------------------------------------------------------------
    // Aufgabe 7: Strings verketten (Skript S. 13 und S. 20).
    // Beispiel: (3, 4) -> "3 + 4 = 7"
    // Falle: "..." + a + b ergibt "34" und nicht 7. Klammern helfen!
    // ------------------------------------------------------------------
    static String summenText(int a, int b) {
        return a + " + " + b + " = " + (a + b);
    }

    // ------------------------------------------------------------------
    // Aufgabe 8: Initialen bilden.
    // Beispiel: ("Wayne", "Gretzky") -> "W.G."
    // Tipp: text.charAt(0) liefert das erste Zeichen (Typ char).
    // Falle: 'W' + '.' ist KEIN String, sondern eine Zahl (char + char = int)!
    // ------------------------------------------------------------------
    static String initialen(String vorname, String nachname) {
        return "" + vorname.charAt(0) + "." + nachname.charAt(0) + ".";
    }

    // ------------------------------------------------------------------
    // Aufgabe 9: Wertebereiche (Skript S. 18).
    // Wie viele Sekunden haben n Jahre (mit je 365 Tagen)?
    // Beispiel: 1 -> 31536000      100 -> 3153600000
    // Falle: 100 Jahre passen nicht mehr in einen int (max. 2147483647).
    //        Rechnest du nur mit int, gibt es einen Überlauf - auch wenn
    //        der Rückgabetyp long ist! Tipp: 365L ist ein long-Literal.
    // ------------------------------------------------------------------
    static long sekundenInJahren(int jahre) {
        return jahre * 365L * 24 * 60 * 60;
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 1: Grunddatentypen und Strings ===");

        abschnitt("Aufgabe 1 - bruttopreis");
        pruefe("bruttopreis(100.0)", 119.0, () -> bruttopreis(100.0));
        pruefe("bruttopreis(0.0)", 0.0, () -> bruttopreis(0.0));

        abschnitt("Aufgabe 2 - celsiusInFahrenheit");
        pruefe("celsiusInFahrenheit(100.0)", 212.0, () -> celsiusInFahrenheit(100.0));
        pruefe("celsiusInFahrenheit(37.0)", 98.6, () -> celsiusInFahrenheit(37.0));
        pruefe("celsiusInFahrenheit(-40.0)", -40.0, () -> celsiusInFahrenheit(-40.0));

        abschnitt("Aufgabe 3 - minutenAlsText");
        pruefe("minutenAlsText(125)", "2 h 5 min", () -> minutenAlsText(125));
        pruefe("minutenAlsText(59)", "0 h 59 min", () -> minutenAlsText(59));
        pruefe("minutenAlsText(180)", "3 h 0 min", () -> minutenAlsText(180));

        abschnitt("Aufgabe 4 - durchschnitt");
        pruefe("durchschnitt(3, 4)", 3.5, () -> durchschnitt(3, 4));
        pruefe("durchschnitt(2, 2)", 2.0, () -> durchschnitt(2, 2));
        pruefe("durchschnitt(-1, 2)", 0.5, () -> durchschnitt(-1, 2));

        abschnitt("Aufgabe 5 - abschneiden");
        pruefe("abschneiden(2.538)", 2, () -> abschneiden(2.538));
        pruefe("abschneiden(9.99)", 9, () -> abschneiden(9.99));
        pruefe("abschneiden(-2.7)", -2, () -> abschneiden(-2.7));

        abschnitt("Aufgabe 6 - zeichenCode / naechstesZeichen");
        pruefe("zeichenCode('A')", 65, () -> zeichenCode('A'));
        pruefe("zeichenCode('a')", 97, () -> zeichenCode('a'));
        pruefe("naechstesZeichen('A')", 'B', () -> naechstesZeichen('A'));
        pruefe("naechstesZeichen('y')", 'z', () -> naechstesZeichen('y'));

        abschnitt("Aufgabe 7 - summenText");
        pruefe("summenText(3, 4)", "3 + 4 = 7", () -> summenText(3, 4));
        pruefe("summenText(10, -2)", "10 + -2 = 8", () -> summenText(10, -2));

        abschnitt("Aufgabe 8 - initialen");
        pruefe("initialen(\"Wayne\", \"Gretzky\")", "W.G.", () -> initialen("Wayne", "Gretzky"));
        pruefe("initialen(\"Leon\", \"Draisaitl\")", "L.D.", () -> initialen("Leon", "Draisaitl"));

        abschnitt("Aufgabe 9 - sekundenInJahren");
        pruefe("sekundenInJahren(1)", 31536000L, () -> sekundenInJahren(1));
        pruefe("sekundenInJahren(100)", 3153600000L, () -> sekundenInJahren(100));

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
