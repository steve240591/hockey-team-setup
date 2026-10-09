/*
 * MODUL 9 - Abstrakte Klassen und Schnittstellen (Interfaces)
 * Passend zum Skript: Lektion 12 (Seiten 38-40), Beispiel Figur/KreisF/RechteckF
 * und Bewegung/BewKreis (FigTest.java, FigMove.java)
 *
 * Wichtig: Schnittstellen-Methoden sind automatisch public. Wer eine
 * Schnittstelle implementiert, muss die Methoden darum auch public deklarieren.
 *
 * MUSTERLÖSUNG - erst anschauen, wenn du es selbst versucht hast!
 */
public class Modul09_AbstraktInterface {

    // ------------------------------------------------------------------
    // Aufgabe 4: Summe der Flächen aller Figuren (dynamische Bindung).
    // ------------------------------------------------------------------
    static double gesamtFlaeche(Figur[] figuren) {
        double summe = 0;
        for (Figur f : figuren) {
            summe += f.flaeche();
        }
        return summe;
    }

    // ------------------------------------------------------------------
    // Aufgabe 5: Die Figur mit der größten Fläche zurückgeben.
    // Nutze istGroesserAls() aus Aufgabe 1. (Das Feld ist nie leer.)
    // ------------------------------------------------------------------
    static Figur groessteFigur(Figur[] figuren) {
        Figur groesste = figuren[0];
        for (Figur f : figuren) {
            if (f.istGroesserAls(groesste)) {
                groesste = f;
            }
        }
        return groesste;
    }

    // ------------------------------------------------------------------
    // Aufgabe 6: Alle beweglichen Objekte um dx und dy verschieben.
    // Das Feld enthält BewKreise UND Schiedsrichter - die Methode kennt nur
    // die Schnittstelle Bewegung. Genau dafür sind Schnittstellen da!
    // ------------------------------------------------------------------
    static void allesVerschieben(Bewegung[] objekte, int dx, int dy) {
        for (Bewegung b : objekte) {
            b.moveX(dx);
            b.moveY(dy);
        }
    }

    // ==================================================================
    //  Tests
    // ==================================================================
    public static void main(String[] args) {
        System.out.println("=== Modul 9: Abstrakte Klassen und Schnittstellen ===");

        abschnitt("Aufgabe 1 - istGroesserAls in Figur");
        pruefe("Kreis(2) groesser als Rechteck(1, 1)", true,
                () -> new KreisF(2).istGroesserAls(new RechteckF(1, 1)));
        pruefe("Rechteck(1, 1) groesser als Kreis(2)", false,
                () -> new RechteckF(1, 1).istGroesserAls(new KreisF(2)));

        abschnitt("Aufgabe 2 - KreisF");
        pruefe("KreisF(1).flaeche()", Math.PI, () -> new KreisF(1).flaeche());
        pruefe("KreisF(1).umfang()", 2 * Math.PI, () -> new KreisF(1).umfang());

        abschnitt("Aufgabe 3 - RechteckF");
        pruefe("RechteckF(3, 4).flaeche()", 12.0, () -> new RechteckF(3, 4).flaeche());
        pruefe("RechteckF(3, 4).umfang()", 14.0, () -> new RechteckF(3, 4).umfang());
        pruefe("setPos() geerbt aus Figur", 7, () -> {
            RechteckF r = new RechteckF(3, 4);
            r.setPos(7, 2);
            return r.getX();
        });

        Figur[] figuren = {new KreisF(1), new RechteckF(3, 4), new KreisF(1.5)};

        abschnitt("Aufgabe 4 - gesamtFlaeche");
        pruefe("gesamtFlaeche(...)", Math.PI + 12 + 2.25 * Math.PI, () -> gesamtFlaeche(figuren));

        abschnitt("Aufgabe 5 - groessteFigur");
        pruefe("groessteFigur(...) ist das Rechteck", figuren[1], () -> groessteFigur(figuren));

        abschnitt("Aufgabe 6 - Schnittstelle Bewegung");
        pruefe("BewKreis.moveX", 5, () -> {
            BewKreis k = new BewKreis(1);
            k.setPos(2, 2);
            k.moveX(3);
            return k.getX();
        });
        pruefe("BewKreis ist auch eine Figur", Math.PI, () -> {
            Figur f = new BewKreis(1);
            return f.flaeche();
        });
        pruefe("Schiedsrichter.moveY", -4, () -> {
            Schiedsrichter s = new Schiedsrichter();
            s.moveY(-4);
            return s.getY();
        });
        pruefe("allesVerschieben(...)", "3,1 13,11", () -> {
            BewKreis k = new BewKreis(1);
            Schiedsrichter s = new Schiedsrichter();
            s.setPos(10, 10);
            Bewegung[] alle = {k, s};
            allesVerschieben(alle, 3, 1);
            return k.getX() + "," + k.getY() + " " + s.getX() + "," + s.getY();
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
// Abstrakte Basisklasse (wie im Skript S. 39). Von Figur selbst können
// keine Instanzen erzeugt werden - probier mal  new Figur()  aus!
// ----------------------------------------------------------------------
abstract class Figur {
    protected int xp;
    protected int yp;

    public void setPos(int xp, int yp) {
        this.xp = xp;
        this.yp = yp;
    }

    public int getX() {
        return xp;
    }

    public int getY() {
        return yp;
    }

    abstract double flaeche();

    abstract double umfang();

    // Aufgabe 1: Eine NICHT-abstrakte Methode darf abstrakte Methoden benutzen!
    // true, wenn diese Figur eine größere Fläche hat als die andere.
    boolean istGroesserAls(Figur andere) {
        return this.flaeche() > andere.flaeche();
    }
}

// Aufgabe 2: KreisF muss die abstrakten Methoden überschreiben.
class KreisF extends Figur {
    private double r;

    KreisF(double r) {
        this.r = r;
    }

    @Override
    double flaeche() {
        return Math.PI * r * r;
    }

    @Override
    double umfang() {
        return 2 * Math.PI * r;
    }
}

// Aufgabe 3: RechteckF mit Länge l und Höhe h.
class RechteckF extends Figur {
    private double l;
    private double h;

    RechteckF(double l, double h) {
        this.l = l;
        this.h = h;
    }

    @Override
    double flaeche() {
        return l * h;
    }

    @Override
    double umfang() {
        return 2 * (l + h);
    }
}

// ----------------------------------------------------------------------
// Schnittstelle Bewegung (wie im Skript S. 40)
// ----------------------------------------------------------------------
interface Bewegung {
    void setPos(int x, int y);

    void moveX(int m);

    void moveY(int m);

    int getX();

    int getY();
}

// Aufgabe 6a: BewKreis ist ein KreisF UND implementiert Bewegung.
// setPos, getX und getY erbt er schon von Figur - es fehlen nur moveX und moveY.
class BewKreis extends KreisF implements Bewegung {

    BewKreis(double r) {
        super(r);
    }

    public void moveX(int mx) {
        xp = xp + mx;
    }

    public void moveY(int my) {
        yp = yp + my;
    }
}

// Aufgabe 6b: Ein Schiedsrichter ist KEINE Figur, kann sich aber bewegen.
// Er implementiert alle fünf Methoden der Schnittstelle selbst.
class Schiedsrichter implements Bewegung {
    private int x;
    private int y;

    public void setPos(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public void moveX(int m) {
        x += m;
    }

    public void moveY(int m) {
        y += m;
    }

    public int getX() {
        return x;
    }

    public int getY() {
        return y;
    }
}
