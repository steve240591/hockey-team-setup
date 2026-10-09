import java.util.Scanner;

/*
 * ABSCHLUSSPROJEKT - Kaderverwaltung (Startgerüst)
 *
 * Die Aufgabenstellung steht in  ABSCHLUSSPROJEKT.md  im selben Ordner.
 * Die beiden Hilfsmethoden leseZahl() und leseText() sind schon fertig -
 * alles andere baust du selbst.
 *
 * Start:  java Kaderverwaltung.java
 *
 * Wichtig: Die Klasse mit main() muss die ERSTE Klasse in der Datei sein.
 * Deine weiteren Klassen (Person, Spieler, Feldspieler, ...) schreibst du
 * UNTER diese Klasse.
 */
public class Kaderverwaltung {

    public static void main(String[] args) {
        Scanner lies = new Scanner(System.in);
        // TODO Stufe 2: Kader anlegen
        int auswahl;

        do {
            System.out.println();
            System.out.println("1 Feldspieler anlegen   2 Torhueter anlegen");
            System.out.println("3 Tor eintragen         4 Vorlage eintragen");
            System.out.println("5 Schuss auf Torhueter  6 Kader anzeigen");
            System.out.println("7 Topscorer             0 Beenden");
            auswahl = leseZahl(lies, "Auswahl: ");

            switch (auswahl) {
                // TODO Stufe 3: die Menüpunkte 1 bis 7 umsetzen
                case 0 -> System.out.println("Tschuess!");
                default -> System.out.println("Noch nicht umgesetzt.");
            }
        } while (auswahl != 0);
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

// TODO Stufe 1: Hier kommen deine Klassen hin.
