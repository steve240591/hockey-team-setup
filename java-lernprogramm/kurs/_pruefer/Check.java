import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.lang.reflect.InvocationTargetException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.regex.Pattern;

/*
 * Prüf-Werkzeuge für die Lektionen. Wird vom Trainer zusammen mit deinem
 * Code (Main.java) und den Tests der Lektion (Pruefung.java) übersetzt.
 * Jedes Ergebnis wird als eine Zeile in eine Protokolldatei geschrieben.
 */
public class Check {

    public interface Berechnung {
        Object berechne() throws Throwable;
    }

    private static PrintStream protokoll;

    public static void start(String datei) throws Exception {
        protokoll = new PrintStream(new FileOutputStream(datei), true, StandardCharsets.UTF_8);
    }

    /** Vergleicht den Rückgabewert von code mit dem erwarteten Wert. */
    public static void gleich(String beschreibung, Object erwartet, Berechnung code) {
        Object ergebnis;
        try {
            ergebnis = code.berechne();
        } catch (Throwable t) {
            ausnahme(beschreibung, t);
            return;
        }
        if (vergleiche(erwartet, ergebnis)) {
            melde("OK", beschreibung, "", "");
        } else {
            melde("FEHLER", beschreibung, alsText(erwartet), alsText(ergebnis));
        }
    }

    /** Startet Main.main() und vergleicht die Bildschirmausgabe. */
    public static void ausgabe(String beschreibung, String erwartet) {
        ausgabe(beschreibung, "", erwartet);
    }

    /** Wie ausgabe(), aber mit Tastatureingabe für Scanner. */
    public static void ausgabe(String beschreibung, String eingabe, String erwartet) {
        String ergebnis;
        try {
            ergebnis = fuehreMainAus(eingabe);
        } catch (Throwable t) {
            ausnahme(beschreibung, t);
            return;
        }
        if (normalisiere(erwartet).equals(normalisiere(ergebnis))) {
            melde("OK", beschreibung, "", "");
        } else {
            melde("FEHLER", beschreibung, normalisiere(erwartet), normalisiere(ergebnis));
        }
    }

    /** Prüft, ob die Ausgabe von Main.main() einen bestimmten Text enthält. */
    public static void ausgabeEnthaelt(String beschreibung, String teil) {
        ausgabeEnthaelt(beschreibung, "", teil);
    }

    /** Wie ausgabeEnthaelt(), aber mit Tastatureingabe für Scanner. */
    public static void ausgabeEnthaelt(String beschreibung, String eingabe, String teil) {
        String ergebnis;
        try {
            ergebnis = fuehreMainAus(eingabe);
        } catch (Throwable t) {
            ausnahme(beschreibung, t);
            return;
        }
        if (ergebnis.contains(teil)) {
            melde("OK", beschreibung, "", "");
        } else {
            melde("FEHLER", beschreibung, "Ausgabe enthält: " + teil, normalisiere(ergebnis));
        }
    }

    /** Prüft, ob der Quelltext (ohne Kommentare und Strings) zum Muster passt. */
    public static void quelltextEnthaelt(String beschreibung, String regex) {
        boolean gefunden = Pattern.compile(regex).matcher(quelltext()).find();
        melde(gefunden ? "OK" : "FEHLER", beschreibung, gefunden ? "" : "kommt im Code vor", gefunden ? "" : "nicht gefunden");
    }

    /** Prüft, ob etwas im Quelltext (ohne Kommentare und Strings) NICHT vorkommt. */
    public static void quelltextOhne(String beschreibung, String regex) {
        boolean gefunden = Pattern.compile(regex).matcher(quelltext()).find();
        melde(gefunden ? "FEHLER" : "OK", beschreibung, gefunden ? "kommt nicht vor" : "", gefunden ? "kommt vor" : "");
    }

    // ------------------------------------------------------------------

    private static String fuehreMainAus(String eingabe) throws Throwable {
        PrintStream altOut = System.out;
        InputStream altIn = System.in;
        ByteArrayOutputStream puffer = new ByteArrayOutputStream();
        System.setOut(new PrintStream(puffer, true, StandardCharsets.UTF_8));
        System.setIn(new ByteArrayInputStream(eingabe.getBytes(StandardCharsets.UTF_8)));
        try {
            Class.forName("Main").getMethod("main", String[].class).invoke(null, (Object) new String[0]);
        } catch (InvocationTargetException e) {
            throw e.getCause();
        } finally {
            System.out.flush();
            System.setOut(altOut);
            System.setIn(altIn);
        }
        return puffer.toString(StandardCharsets.UTF_8);
    }

    private static String quelltext() {
        try {
            String code = Files.readString(Path.of("Main.java"), StandardCharsets.UTF_8);
            return code.replaceAll("(?s)/\\*.*?\\*/", " ")
                    .replaceAll("//[^\n]*", " ")
                    .replaceAll("\"(\\\\.|[^\"\\\\])*\"", "\"\"")
                    .replaceAll("'(\\\\.|[^'\\\\])'", "' '");
        } catch (Exception e) {
            return "";
        }
    }

    private static void ausnahme(String beschreibung, Throwable t) {
        if (t instanceof UnsupportedOperationException && "TODO".equals(t.getMessage())) {
            melde("OFFEN", beschreibung, "", "");
        } else if (t instanceof StackOverflowError) {
            melde("ABSTURZ", beschreibung, "", "StackOverflowError - endlose Rekursion?");
        } else {
            melde("ABSTURZ", beschreibung, "", t.toString());
        }
    }

    private static boolean vergleiche(Object a, Object b) {
        if (a instanceof Double x && b instanceof Double y) {
            return Math.abs(x - y) <= 1e-9 * Math.max(1.0, Math.abs(x));
        }
        return Arrays.deepEquals(new Object[] {a}, new Object[] {b});
    }

    private static String alsText(Object o) {
        if (o instanceof String s) {
            return "\"" + s + "\"";
        }
        if (o instanceof Character c) {
            return "'" + c + "'";
        }
        if (o instanceof Long l) {
            return l + "L";
        }
        String text = Arrays.deepToString(new Object[] {o});
        return text.substring(1, text.length() - 1);
    }

    private static String normalisiere(String s) {
        String[] zeilen = s.replace("\r\n", "\n").split("\n", -1);
        StringBuilder sb = new StringBuilder();
        for (String zeile : zeilen) {
            sb.append(zeile.stripTrailing()).append('\n');
        }
        return sb.toString().stripTrailing();
    }

    private static void melde(String status, String beschreibung, String erwartet, String erhalten) {
        protokoll.println(status + "\t" + schuetze(beschreibung) + "\t" + schuetze(erwartet) + "\t" + schuetze(erhalten));
    }

    private static String schuetze(String s) {
        return s.replace("\\", "\\\\").replace("\t", "\\t").replace("\r", "").replace("\n", "\\n");
    }
}
