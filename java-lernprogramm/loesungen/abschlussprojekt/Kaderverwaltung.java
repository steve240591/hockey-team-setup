import java.util.Scanner;

/*
 * ABSCHLUSSPROJEKT - Kaderverwaltung (Musterlösung)
 *
 * Nutzt alles aus dem Skript (Lektion 1-13): Klassen, Datenkapselung,
 * Konstruktoren, Vererbung, abstrakte Klassen, Schnittstellen,
 * Klassenvariablen, Felder, Kontrollstrukturen und Scanner-Eingabe.
 *
 * Start:  java Kaderverwaltung.java
 *   oder  javac Kaderverwaltung.java  und dann  java Kaderverwaltung
 *
 * Wichtig: Die Klasse mit main() muss die ERSTE Klasse in der Datei sein,
 * wenn du das Programm direkt mit  java Kaderverwaltung.java  startest.
 */
public class Kaderverwaltung {

    public static void main(String[] args) {
        Scanner lies = new Scanner(System.in);
        Kader kader = new Kader("Adler Mannheim");
        int auswahl;

        System.out.println("Kaderverwaltung " + kader.getTeamname());
        do {
            zeigeMenue();
            auswahl = leseZahl(lies, "Auswahl: ");
            switch (auswahl) {
                case 1 -> spielerAnlegen(lies, kader, false);
                case 2 -> spielerAnlegen(lies, kader, true);
                case 3 -> torEintragen(lies, kader);
                case 4 -> vorlageEintragen(lies, kader);
                case 5 -> schussEintragen(lies, kader);
                case 6 -> kader.ausgeben();
                case 7 -> topScorerAnzeigen(kader);
                case 0 -> System.out.println("Tschuess!");
                default -> System.out.println("Ungueltige Auswahl.");
            }
        } while (auswahl != 0);
    }

    static void zeigeMenue() {
        System.out.println();
        System.out.println("1 Feldspieler anlegen   2 Torhueter anlegen");
        System.out.println("3 Tor eintragen         4 Vorlage eintragen");
        System.out.println("5 Schuss auf Torhueter  6 Kader anzeigen");
        System.out.println("7 Topscorer             0 Beenden");
    }

    static void spielerAnlegen(Scanner lies, Kader kader, boolean torhueter) {
        String name = leseText(lies, "Name: ");
        int nummer = leseZahl(lies, "Rueckennummer (1-99): ");
        if (nummer < 1 || nummer > 99) {
            System.out.println("Nummer muss zwischen 1 und 99 liegen.");
            return;
        }
        Spieler neu = torhueter ? new Torhueter(name, nummer) : new Feldspieler(name, nummer);
        if (kader.hinzufuegen(neu)) {
            System.out.println("Angelegt: " + neu);
        } else {
            System.out.println("Nicht moeglich: Kader voll oder Nummer schon vergeben.");
        }
    }

    static void torEintragen(Scanner lies, Kader kader) {
        Feldspieler f = sucheFeldspieler(lies, kader);
        if (f != null) {
            f.torErzielen();
            System.out.println("Tor fuer " + f.getName() + "! " + f.statistik());
        }
    }

    static void vorlageEintragen(Scanner lies, Kader kader) {
        Feldspieler f = sucheFeldspieler(lies, kader);
        if (f != null) {
            f.vorlageGeben();
            System.out.println("Vorlage fuer " + f.getName() + ". " + f.statistik());
        }
    }

    static void schussEintragen(Scanner lies, Kader kader) {
        Spieler s = kader.suche(leseZahl(lies, "Nummer des Torhueters: "));
        if (!(s instanceof Torhueter)) {
            System.out.println("Kein Torhueter mit dieser Nummer.");
            return;
        }
        Torhueter t = (Torhueter) s;
        int ergebnis = leseZahl(lies, "1 = gehalten, 2 = Gegentor: ");
        if (ergebnis == 1) {
            t.parade();
        } else if (ergebnis == 2) {
            t.gegentor();
        } else {
            System.out.println("Ungueltige Eingabe.");
            return;
        }
        System.out.println(t.getName() + ": " + t.statistik());
    }

    static void topScorerAnzeigen(Kader kader) {
        Feldspieler top = kader.topScorer();
        if (top == null) {
            System.out.println("Noch keine Feldspieler im Kader.");
        } else {
            System.out.println("Topscorer: " + top);
        }
    }

    static Feldspieler sucheFeldspieler(Scanner lies, Kader kader) {
        Spieler s = kader.suche(leseZahl(lies, "Rueckennummer: "));
        if (s instanceof Feldspieler) {
            return (Feldspieler) s;
        }
        System.out.println("Kein Feldspieler mit dieser Nummer.");
        return null;
    }

    // Liest so lange, bis eine ganze Zahl eingegeben wurde.
    static int leseZahl(Scanner lies, String frage) {
        System.out.print(frage);
        while (!lies.hasNextInt()) {
            lies.next();
            System.out.print("Bitte eine ganze Zahl eingeben: ");
        }
        int zahl = lies.nextInt();
        lies.nextLine(); // Rest der Zeile (Enter) verwerfen
        return zahl;
    }

    static String leseText(Scanner lies, String frage) {
        System.out.print(frage);
        return lies.nextLine().trim();
    }
}

// ----------------------------------------------------------------------
// Abstrakte Basisklasse für alle Personen im Verein
// ----------------------------------------------------------------------
abstract class Person {
    private static int anzahlPersonen = 0; // Klassenvariable
    private final String name;

    Person(String name) {
        this.name = name;
        anzahlPersonen++;
    }

    String getName() {
        return name;
    }

    static int getAnzahlPersonen() {
        return anzahlPersonen;
    }

    abstract String rolle();
}

// ----------------------------------------------------------------------
// Schnittstelle: Alles, was eine Statistik liefern kann
// ----------------------------------------------------------------------
interface Auswertbar {
    String statistik();
}

// ----------------------------------------------------------------------
// Gemeinsame Basisklasse für Feldspieler und Torhüter
// ----------------------------------------------------------------------
abstract class Spieler extends Person implements Auswertbar {
    private final int nummer;

    Spieler(String name, int nummer) {
        super(name);
        this.nummer = nummer;
    }

    int getNummer() {
        return nummer;
    }

    @Override
    public String toString() {
        return "#" + nummer + " " + getName() + " (" + rolle() + ")  " + statistik();
    }
}

class Feldspieler extends Spieler {
    private int tore;
    private int vorlagen;

    Feldspieler(String name, int nummer) {
        super(name, nummer);
    }

    void torErzielen() {
        tore++;
    }

    void vorlageGeben() {
        vorlagen++;
    }

    int punkte() {
        return tore + vorlagen;
    }

    @Override
    String rolle() {
        return "Feldspieler";
    }

    @Override
    public String statistik() {
        return "Tore: " + tore + "  Vorlagen: " + vorlagen + "  Punkte: " + punkte();
    }
}

class Torhueter extends Spieler {
    private int paraden;
    private int gegentore;

    Torhueter(String name, int nummer) {
        super(name, nummer);
    }

    void parade() {
        paraden++;
    }

    void gegentor() {
        gegentore++;
    }

    // Fangquote in Prozent, auf eine Nachkommastelle gerundet
    double fangquote() {
        int schuesse = paraden + gegentore;
        if (schuesse == 0) {
            return 0.0;
        }
        return Math.round(1000.0 * paraden / schuesse) / 10.0;
    }

    @Override
    String rolle() {
        return "Torhueter";
    }

    @Override
    public String statistik() {
        return "Paraden: " + paraden + "  Gegentore: " + gegentore + "  Fangquote: " + fangquote() + " %";
    }
}

// ----------------------------------------------------------------------
// Der Kader verwaltet bis zu MAX_SPIELER Spieler in einem Feld.
// ----------------------------------------------------------------------
class Kader {
    static final int MAX_SPIELER = 25;

    private final String teamname;
    private final Spieler[] spieler = new Spieler[MAX_SPIELER];
    private int anzahl = 0;

    Kader(String teamname) {
        this.teamname = teamname;
    }

    String getTeamname() {
        return teamname;
    }

    boolean hinzufuegen(Spieler neu) {
        if (anzahl == MAX_SPIELER || suche(neu.getNummer()) != null) {
            return false;
        }
        spieler[anzahl] = neu;
        anzahl++;
        return true;
    }

    // Liefert den Spieler mit der Nummer oder null, wenn es ihn nicht gibt.
    Spieler suche(int nummer) {
        for (int i = 0; i < anzahl; i++) {
            if (spieler[i].getNummer() == nummer) {
                return spieler[i];
            }
        }
        return null;
    }

    Feldspieler topScorer() {
        Feldspieler top = null;
        for (int i = 0; i < anzahl; i++) {
            if (spieler[i] instanceof Feldspieler) {
                Feldspieler f = (Feldspieler) spieler[i];
                if (top == null || f.punkte() > top.punkte()) {
                    top = f;
                }
            }
        }
        return top;
    }

    void ausgeben() {
        System.out.println("Kader " + teamname + " (" + anzahl + " von " + MAX_SPIELER + " Plaetzen)");
        for (int i = 0; i < anzahl; i++) {
            System.out.println("  " + spieler[i]);
        }
        System.out.println("Personen insgesamt erzeugt: " + Person.getAnzahlPersonen());
    }
}
