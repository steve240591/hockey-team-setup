/*
 * MODUL 5 - Klassen, Objekte, Instanzvariablen, Instanzmethoden
 * Passend zum Skript: Lektion 8 (Seiten 23-28), Beispiel Fahrrad1/Fahrrad2
 *
 * Statt Fahrrädern modellieren wir hier Eishockeyspieler. Die Klasse
 * Spieler steht unten in derselben Datei (eine Datei darf nur EINE
 * public-Klasse enthalten, aber beliebig viele weitere Klassen - Skript S. 11).
 *
 * In diesem Modul greifen wir noch DIREKT auf die Instanzvariablen zu
 * (z. B.  s.tore = 3;) - genau wie im Skript bei Fahrrad1. Wie man das
 * besser macht (Datenkapselung), kommt in Modul 6.
 *
 * MUSTERLÖSUNG - erst anschauen, wenn du es selbst versucht hast!
 */
public class Modul05_KlassenObjekte {

    // ------------------------------------------------------------------
    // Aufgabe 4: Erzeuge mit new eine Instanz von Spieler, setze name und
    // nummer und gib sie zurück. (tore und vorlagen bleiben 0.)
    // ------------------------------------------------------------------
    static Spieler erzeugeSpieler(String name, int nummer) {
        Spieler s = new Spieler();
        s.name = name;
        s.nummer = nummer;
        return s;
    }

    // ------------------------------------------------------------------
    // Aufgabe 5: Verschachtelter Methodenaufruf (Skript S. 27).
    // Liefere die Länge des Namens - in EINER Zeile mit liefereName().
    // Beispiel: Spieler "Crosby" -> 6
    // ------------------------------------------------------------------
    static int namensLaenge(Spieler s) {
        return s.liefereName().length();
    }

    // ------------------------------------------------------------------
    // Aufgabe 6: Welcher Spieler hat mehr Punkte? Gib das Objekt zurück.
    // Bei Gleichstand gewinnt a.
    // ------------------------------------------------------------------
    static Spieler besserer(Spieler a, Spieler b) {
        return b.punkte() > a.punkte() ? b : a;
    }

    // ------------------------------------------------------------------
    // Aufgabe 7 (Vorhersage): Referenzen! Was gibt diese Methode zurück?
    //     Spieler a = new Spieler();
    //     a.tore = 1;
    //     Spieler b = a;
    //     b.tore = 5;
    //     return a.tore;
    // Ersetze die throw-Zeile durch  return <dein Tipp>;
    // ------------------------------------------------------------------
    static int vorhersageReferenz() {
        return 5; // b = a kopiert nur die Referenz: a und b zeigen auf DASSELBE Objekt
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 5: Klassen und Objekte ===");

        abschnitt("Aufgabe 1 - torErzielen / vorlageGeben");
        pruefe("neuer Spieler hat 0 Tore", 0, () -> new Spieler().tore);
        pruefe("torErzielen() liefert neue Toranzahl", 1, () -> new Spieler().torErzielen());
        pruefe("zweimal torErzielen()", 2, () -> {
            Spieler s = new Spieler();
            s.torErzielen();
            return s.torErzielen();
        });
        pruefe("vorlageGeben() zweimal", 2, () -> {
            Spieler s = new Spieler();
            s.vorlageGeben();
            s.vorlageGeben();
            return s.vorlagen;
        });

        abschnitt("Aufgabe 2 - punkte");
        pruefe("2 Tore + 3 Vorlagen", 5, () -> {
            Spieler s = new Spieler();
            s.tore = 2;
            s.vorlagen = 3;
            return s.punkte();
        });

        abschnitt("Aufgabe 3 - beschreibung");
        pruefe("beschreibung()", "#87 Crosby: 2 Tore, 1 Vorlagen, 3 Punkte", () -> {
            Spieler s = new Spieler();
            s.name = "Crosby";
            s.nummer = 87;
            s.tore = 2;
            s.vorlagen = 1;
            return s.beschreibung();
        });

        abschnitt("Aufgabe 4 - erzeugeSpieler");
        pruefe("Name gesetzt", "Ovechkin", () -> erzeugeSpieler("Ovechkin", 8).name);
        pruefe("Nummer gesetzt", 8, () -> erzeugeSpieler("Ovechkin", 8).nummer);
        pruefe("Tore noch 0", 0, () -> erzeugeSpieler("Ovechkin", 8).tore);

        abschnitt("Aufgabe 5 - namensLaenge");
        pruefe("namensLaenge(Crosby)", 6, () -> {
            Spieler s = new Spieler();
            s.name = "Crosby";
            return namensLaenge(s);
        });

        abschnitt("Aufgabe 6 - besserer");
        Spieler a = new Spieler();
        a.tore = 3;
        Spieler b = new Spieler();
        b.tore = 1;
        b.vorlagen = 4;
        Spieler c = new Spieler();
        c.vorlagen = 3;
        pruefe("b hat mehr Punkte", b, () -> besserer(a, b));
        pruefe("b hat mehr Punkte (andere Reihenfolge)", b, () -> besserer(b, a));
        pruefe("Gleichstand -> a", a, () -> besserer(a, c));

        abschnitt("Aufgabe 7 - Vorhersage");
        Spieler x = new Spieler();
        x.tore = 1;
        Spieler y = x;
        y.tore = 5;
        int ergebnis = x.tore;
        pruefe("vorhersageReferenz()", ergebnis, () -> vorhersageReferenz());

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

/*
 * Die Klasse Spieler - wie Fahrrad2 im Skript.
 * Die Instanzvariablen sind schon da, die Methoden fehlen noch.
 */
class Spieler {
    String name;
    int nummer;
    int tore;
    int vorlagen;

    // Aufgabe 1: Ein Tor erzielen: tore um 1 erhöhen und die neue Toranzahl
    // zurückgeben (vgl. lenken() im Skript). vorlageGeben() funktioniert genauso.
    int torErzielen() {
        tore = tore + 1;
        return tore;
    }

    int vorlageGeben() {
        vorlagen++;
        return vorlagen;
    }

    // Aufgabe 2: Scorerpunkte = Tore + Vorlagen
    int punkte() {
        return tore + vorlagen;
    }

    // Aufgabe 3: Text in genau diesem Format:
    // "#87 Crosby: 2 Tore, 1 Vorlagen, 3 Punkte"
    // Tipp: Nutze deine Methode punkte().
    String beschreibung() {
        return "#" + nummer + " " + name + ": " + tore + " Tore, " + vorlagen + " Vorlagen, "
                + punkte() + " Punkte";
    }

    // (vorgegeben, wie liefereEigentuemer() im Skript S. 27)
    String liefereName() {
        return this.name;
    }
}
