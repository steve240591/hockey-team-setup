import MeinPak.*;

/*
 * Musterlösung zur Lektion "Praxis: Ein eigenes Paket" (vgl. Skript S. 17).
 * Im Ordner extras/pakete ausführen:
 *     javac PaketTest.java
 *     java PaketTest
 */
public class PaketTest {
    public static void main(String[] str) {
        Komma k = new Komma();
        k.komma();
        Strich s = new Strich();
        s.strich();
    }
}
