import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import javax.tools.Diagnostic;
import javax.tools.DiagnosticCollector;
import javax.tools.JavaCompiler;
import javax.tools.JavaFileObject;
import javax.tools.StandardJavaFileManager;
import javax.tools.ToolProvider;
import java.awt.Desktop;
import java.awt.GraphicsEnvironment;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.BindException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;

/*
 * JAVA-TRAINER - lokale Lernumgebung im Browser
 *
 * Start (im Ordner java-lernprogramm):
 *     java Trainer.java
 * oder per Doppelklick auf starten.bat (Windows) bzw. starten.sh (macOS/Linux).
 *
 * Der Trainer startet einen kleinen Webserver, der NUR auf diesem Rechner
 * erreichbar ist (localhost), und öffnet die Oberfläche im Browser.
 * Dein Code wird mit dem javac deines JDK übersetzt und in einem eigenen
 * Java-Prozess mit Zeitlimit ausgeführt.
 *
 * Selbsttest aller Lektionen (für Entwickler):
 *     java Trainer.java --selbsttest
 */
public class Trainer {

    static final int ZEITLIMIT_SEKUNDEN = 5;
    static final int MAX_AUSGABE = 64 * 1024;
    static final int MAX_ANFRAGE = 2 * 1024 * 1024;

    static Path basis;
    static String token;
    static int port;

    public static void main(String[] args) throws Exception {
        basis = findeBasis();
        if (ToolProvider.getSystemJavaCompiler() == null) {
            System.err.println("Kein Java-Compiler gefunden. Bitte ein JDK installieren (nicht nur eine JRE).");
            System.exit(1);
        }
        if (args.length > 0 && args[0].equals("--selbsttest")) {
            System.exit(Selbsttest.ausfuehren() ? 0 : 1);
        }

        byte[] zufall = new byte[24];
        new SecureRandom().nextBytes(zufall);
        token = HexFormat.of().formatHex(zufall);

        HttpServer server = null;
        for (int p = 8080; p < 8100 && server == null; p++) {
            try {
                server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), p), 0);
                port = p;
            } catch (BindException belegt) {
                // nächsten Port probieren
            }
        }
        if (server == null) {
            System.err.println("Kein freier Port zwischen 8080 und 8099 gefunden.");
            System.exit(1);
        }
        server.createContext("/", Trainer::bearbeite);
        server.setExecutor(Executors.newFixedThreadPool(4));
        server.start();

        String url = "http://localhost:" + port + "/";
        System.out.println();
        System.out.println("  Java-Trainer laeuft:  " + url);
        System.out.println("  (Falls sich der Browser nicht oeffnet: Adresse oben in den Browser kopieren.)");
        System.out.println("  Beenden mit Strg+C oder durch Schliessen dieses Fensters.");
        System.out.println();
        oeffneBrowser(url);
    }

    static Path findeBasis() {
        for (Path kandidat : List.of(Path.of(""), Path.of("java-lernprogramm"))) {
            if (Files.isDirectory(kandidat.resolve("kurs")) && Files.isDirectory(kandidat.resolve("web"))) {
                return kandidat.toAbsolutePath().normalize();
            }
        }
        System.err.println("Ordner 'kurs' und 'web' nicht gefunden. Bitte im Ordner java-lernprogramm starten.");
        System.exit(1);
        return null;
    }

    static void oeffneBrowser(String url) {
        try {
            if (!GraphicsEnvironment.isHeadless() && Desktop.isDesktopSupported()
                    && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
                Desktop.getDesktop().browse(URI.create(url));
            }
        } catch (Exception e) {
            // dann eben von Hand öffnen
        }
    }

    // ==================================================================
    //  HTTP
    // ==================================================================

    static void bearbeite(HttpExchange ex) throws IOException {
        try {
            // Schutz: nur Anfragen an localhost (verhindert DNS-Rebinding)
            String host = ex.getRequestHeaders().getFirst("Host");
            if (host == null || !(host.equals("localhost:" + port) || host.equals("127.0.0.1:" + port))) {
                sende(ex, 403, "text/plain", "Verboten");
                return;
            }
            String pfad = ex.getRequestURI().getPath();
            if (pfad.startsWith("/api/")) {
                bearbeiteApi(ex, pfad);
            } else {
                sendeDatei(ex, pfad);
            }
        } catch (Exception e) {
            e.printStackTrace();
            sende(ex, 500, "text/plain", "Interner Fehler: " + e);
        } finally {
            ex.close();
        }
    }

    static void bearbeiteApi(HttpExchange ex, String pfad) throws Exception {
        // Schutz: Nur unsere eigene Seite kennt das Token. Andere Webseiten
        // können so keine Programme auf diesem Rechner starten.
        String herkunft = ex.getRequestHeaders().getFirst("Origin");
        boolean herkunftOk = herkunft == null || herkunft.equals("http://localhost:" + port)
                || herkunft.equals("http://127.0.0.1:" + port);
        if (!herkunftOk || !token.equals(ex.getRequestHeaders().getFirst("X-Token"))) {
            sende(ex, 403, "text/plain", "Verboten");
            return;
        }
        String methode = ex.getRequestMethod();
        Map<String, String> parameter = parameter(ex.getRequestURI().getRawQuery());

        switch (pfad) {
            case "/api/kurs" -> sende(ex, 200, "application/json", Kurs.alsJson(Kurs.laden()));
            case "/api/loesung" -> {
                Lektion l = Kurs.finde(parameter.get("id"));
                sende(ex, l == null ? 404 : 200, "application/json",
                        l == null ? "{}" : "{\"loesung\":" + Json.text(l.text("loesung")) + "}");
            }
            case "/api/pruefen" -> {
                Lektion l = Kurs.finde(parameter.get("id"));
                if (l == null || !methode.equals("POST")) {
                    sende(ex, 404, "text/plain", "Lektion nicht gefunden");
                    return;
                }
                sende(ex, 200, "application/json", Pruefer.pruefen(l.text("pruefung"), leseText(ex)).alsJson());
            }
            case "/api/ausfuehren" -> {
                String eingabe = "";
                String kodiert = ex.getRequestHeaders().getFirst("X-Eingabe");
                if (kodiert != null && !kodiert.isEmpty()) {
                    eingabe = new String(Base64.getDecoder().decode(kodiert), StandardCharsets.UTF_8);
                }
                sende(ex, 200, "application/json", Pruefer.ausfuehren(leseText(ex), eingabe));
            }
            case "/api/fortschritt" -> {
                Path datei = basis.resolve("fortschritt.json");
                if (methode.equals("POST")) {
                    Files.writeString(datei, leseText(ex), StandardCharsets.UTF_8);
                    sende(ex, 200, "application/json", "{\"ok\":true}");
                } else {
                    sende(ex, 200, "application/json",
                            Files.exists(datei) ? Files.readString(datei, StandardCharsets.UTF_8) : "{}");
                }
            }
            default -> sende(ex, 404, "text/plain", "Unbekannt");
        }
    }

    static void sendeDatei(HttpExchange ex, String pfad) throws IOException {
        if (pfad.equals("/")) {
            pfad = "/index.html";
        }
        Path web = basis.resolve("web").normalize();
        Path datei = web.resolve(pfad.substring(1)).normalize();
        if (!datei.startsWith(web) || !Files.isRegularFile(datei)) {
            sende(ex, 404, "text/plain", "Nicht gefunden");
            return;
        }
        String name = datei.getFileName().toString();
        String typ = name.endsWith(".html") ? "text/html"
                : name.endsWith(".css") ? "text/css"
                : name.endsWith(".js") ? "text/javascript"
                : name.endsWith(".svg") ? "image/svg+xml"
                : "application/octet-stream";
        if (name.equals("index.html")) {
            sende(ex, 200, typ, Files.readString(datei, StandardCharsets.UTF_8).replace("__TOKEN__", token));
        } else {
            sendeBytes(ex, 200, typ, Files.readAllBytes(datei));
        }
    }

    static String leseText(HttpExchange ex) throws IOException {
        try (InputStream in = ex.getRequestBody()) {
            byte[] daten = in.readNBytes(MAX_ANFRAGE + 1);
            if (daten.length > MAX_ANFRAGE) {
                throw new IOException("Anfrage zu groß");
            }
            return new String(daten, StandardCharsets.UTF_8);
        }
    }

    static Map<String, String> parameter(String query) {
        Map<String, String> ergebnis = new LinkedHashMap<>();
        if (query != null) {
            for (String teil : query.split("&")) {
                int gleich = teil.indexOf('=');
                if (gleich > 0) {
                    ergebnis.put(URLDecoder.decode(teil.substring(0, gleich), StandardCharsets.UTF_8),
                            URLDecoder.decode(teil.substring(gleich + 1), StandardCharsets.UTF_8));
                }
            }
        }
        return ergebnis;
    }

    static void sende(HttpExchange ex, int status, String typ, String text) throws IOException {
        sendeBytes(ex, status, typ, text.getBytes(StandardCharsets.UTF_8));
    }

    static void sendeBytes(HttpExchange ex, int status, String typ, byte[] daten) throws IOException {
        ex.getResponseHeaders().set("Content-Type", typ + "; charset=utf-8");
        ex.getResponseHeaders().set("Cache-Control", "no-store");
        ex.sendResponseHeaders(status, daten.length);
        try (OutputStream out = ex.getResponseBody()) {
            out.write(daten);
        }
    }
}

// ======================================================================
//  Kurs: Lektionen aus dem Ordner "kurs" lesen
// ======================================================================

/** Eine Lektion besteht aus benannten Abschnitten ("=== name" in der Datei). */
record Lektion(String id, String kapitel, Map<String, List<String>> abschnitte) {

    String text(String name) {
        List<String> liste = abschnitte.get(name);
        return liste == null || liste.isEmpty() ? "" : liste.get(0);
    }

    List<String> alle(String name) {
        return abschnitte.getOrDefault(name, List.of());
    }

    String typ() {
        String typ = text("typ");
        return typ.isEmpty() ? "code" : typ;
    }
}

record Kapitel(String nummer, String titel, String untertitel) {
}

class Kurs {

    static List<Kapitel> kapitel() throws IOException {
        List<Kapitel> ergebnis = new ArrayList<>();
        for (String zeile : Files.readAllLines(Trainer.basis.resolve("kurs/kapitel.txt"), StandardCharsets.UTF_8)) {
            String[] teile = zeile.split("\\|");
            if (teile.length >= 2 && !zeile.isBlank() && !zeile.startsWith("#")) {
                ergebnis.add(new Kapitel(teile[0].trim(), teile[1].trim(), teile.length > 2 ? teile[2].trim() : ""));
            }
        }
        return ergebnis;
    }

    static List<Lektion> laden() throws IOException {
        List<Lektion> lektionen = new ArrayList<>();
        try (Stream<Path> dateien = Files.list(Trainer.basis.resolve("kurs"))) {
            for (Path datei : dateien.filter(d -> d.toString().endsWith(".txt"))
                    .filter(d -> !d.getFileName().toString().equals("kapitel.txt"))
                    .sorted().toList()) {
                lektionen.add(lese(datei));
            }
        }
        return lektionen;
    }

    static Lektion finde(String id) throws IOException {
        if (id == null) {
            return null;
        }
        for (Lektion l : laden()) {
            if (l.id().equals(id)) {
                return l;
            }
        }
        return null;
    }

    static Lektion lese(Path datei) throws IOException {
        String name = datei.getFileName().toString();
        String id = name.substring(0, name.length() - 4);
        Map<String, List<String>> abschnitte = new LinkedHashMap<>();
        String aktuell = null;
        StringBuilder inhalt = new StringBuilder();
        for (String zeile : Files.readAllLines(datei, StandardCharsets.UTF_8)) {
            if (zeile.startsWith("=== ")) {
                if (aktuell != null) {
                    abschnitte.computeIfAbsent(aktuell, k -> new ArrayList<>()).add(bereinige(inhalt.toString()));
                }
                aktuell = zeile.substring(4).trim();
                inhalt.setLength(0);
            } else {
                inhalt.append(zeile).append('\n');
            }
        }
        if (aktuell != null) {
            abschnitte.computeIfAbsent(aktuell, k -> new ArrayList<>()).add(bereinige(inhalt.toString()));
        }
        return new Lektion(id, id.substring(0, 2), abschnitte);
    }

    /** Leere Zeilen am Anfang und Ende entfernen, Einrückung behalten. */
    static String bereinige(String text) {
        String[] zeilen = text.split("\n", -1);
        int start = 0;
        int ende = zeilen.length;
        while (start < ende && zeilen[start].isBlank()) {
            start++;
        }
        while (ende > start && zeilen[ende - 1].isBlank()) {
            ende--;
        }
        return String.join("\n", java.util.Arrays.copyOfRange(zeilen, start, ende));
    }

    static String alsJson(List<Lektion> lektionen) throws IOException {
        StringBuilder sb = new StringBuilder("{\"kapitel\":[");
        List<Kapitel> kapitel = kapitel();
        for (int i = 0; i < kapitel.size(); i++) {
            Kapitel k = kapitel.get(i);
            sb.append(i > 0 ? "," : "").append("{\"nummer\":").append(Json.text(k.nummer()))
                    .append(",\"titel\":").append(Json.text(k.titel()))
                    .append(",\"untertitel\":").append(Json.text(k.untertitel())).append("}");
        }
        sb.append("],\"lektionen\":[");
        for (int i = 0; i < lektionen.size(); i++) {
            Lektion l = lektionen.get(i);
            sb.append(i > 0 ? "," : "").append("{");
            sb.append("\"id\":").append(Json.text(l.id()));
            sb.append(",\"kapitel\":").append(Json.text(l.kapitel()));
            sb.append(",\"typ\":").append(Json.text(l.typ()));
            sb.append(",\"titel\":").append(Json.text(l.text("titel")));
            sb.append(",\"xp\":").append(l.text("xp").isEmpty() ? (l.typ().equals("code") ? "10" : "5") : l.text("xp"));
            sb.append(",\"erklaerung\":").append(Json.text(l.text("erklaerung")));
            sb.append(",\"aufgabe\":").append(Json.text(l.text("aufgabe")));
            sb.append(",\"vorlage\":").append(Json.text(l.text("vorlage")));
            sb.append(",\"tipps\":").append(Json.liste(l.alle("tipp")));
            sb.append(",\"hatLoesung\":").append(!l.text("loesung").isEmpty());
            if (l.typ().equals("quiz")) {
                List<String> optionen = new ArrayList<>();
                int richtig = -1;
                for (String zeile : l.text("optionen").split("\n")) {
                    if (zeile.startsWith("+ ") || zeile.startsWith("- ")) {
                        if (zeile.startsWith("+ ")) {
                            richtig = optionen.size();
                        }
                        optionen.add(zeile.substring(2));
                    }
                }
                sb.append(",\"frage\":").append(Json.text(l.text("frage")));
                sb.append(",\"optionen\":").append(Json.liste(optionen));
                sb.append(",\"richtig\":").append(richtig);
                sb.append(",\"nachher\":").append(Json.text(l.text("nachher")));
            }
            sb.append("}");
        }
        return sb.append("]}").toString();
    }
}

class Json {
    static String text(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                default -> {
                    if (c < 0x20 || c == '<' || c == '>' || c == '&' || c == 0x2028 || c == 0x2029) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        return sb.append('"').toString();
    }

    static String liste(List<String> werte) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < werte.size(); i++) {
            sb.append(i > 0 ? "," : "").append(text(werte.get(i)));
        }
        return sb.append("]").toString();
    }
}

// ======================================================================
//  Pruefer: übersetzen, ausführen, Tests auswerten
// ======================================================================

record Diagnose(String datei, long zeile, long spalte, String meldung) {
}

record Test(String status, String beschreibung, String erwartet, String erhalten) {
}

record Lauf(String ausgabe, boolean zeitlimit, int exitCode) {
}

record Pruefergebnis(String status, List<Diagnose> diagnosen, List<Test> tests, String ausgabe) {

    boolean bestanden() {
        return status.equals("bestanden");
    }

    String alsJson() {
        StringBuilder sb = new StringBuilder("{\"status\":").append(Json.text(status));
        sb.append(",\"diagnosen\":[");
        for (int i = 0; i < diagnosen.size(); i++) {
            Diagnose d = diagnosen.get(i);
            sb.append(i > 0 ? "," : "").append("{\"datei\":").append(Json.text(d.datei()))
                    .append(",\"zeile\":").append(d.zeile()).append(",\"spalte\":").append(d.spalte())
                    .append(",\"meldung\":").append(Json.text(d.meldung())).append("}");
        }
        sb.append("],\"tests\":[");
        for (int i = 0; i < tests.size(); i++) {
            Test t = tests.get(i);
            sb.append(i > 0 ? "," : "").append("{\"status\":").append(Json.text(t.status()))
                    .append(",\"beschreibung\":").append(Json.text(t.beschreibung()))
                    .append(",\"erwartet\":").append(Json.text(t.erwartet()))
                    .append(",\"erhalten\":").append(Json.text(t.erhalten())).append("}");
        }
        return sb.append("],\"ausgabe\":").append(Json.text(ausgabe)).append("}").toString();
    }
}

class Pruefer {

    static Pruefergebnis pruefen(String pruefung, String code) throws IOException, InterruptedException {
        Path ordner = Files.createTempDirectory("javatrainer");
        try {
            Files.writeString(ordner.resolve("Main.java"), code, StandardCharsets.UTF_8);
            Files.copy(Trainer.basis.resolve("kurs/_pruefer/Check.java"), ordner.resolve("Check.java"));
            Files.writeString(ordner.resolve("Pruefung.java"), """
                    public class Pruefung {
                        public static void main(String[] args) throws Exception {
                            Check.start(args[0]);
                    __TESTS__
                        }
                    }
                    """.replace("__TESTS__", pruefung.indent(8)), StandardCharsets.UTF_8);

            List<Diagnose> diagnosen = kompiliere(ordner, "Main.java", "Check.java", "Pruefung.java");
            if (!diagnosen.isEmpty()) {
                return new Pruefergebnis("kompilierfehler", diagnosen, List.of(), "");
            }
            Path protokoll = ordner.resolve("ergebnis.txt");
            Lauf lauf = starte(ordner, "Pruefung", "", protokoll.toString());
            List<Test> tests = new ArrayList<>();
            if (Files.exists(protokoll)) {
                for (String zeile : Files.readAllLines(protokoll, StandardCharsets.UTF_8)) {
                    String[] f = zeile.split("\t", -1);
                    if (f.length == 4) {
                        tests.add(new Test(f[0], entschluessle(f[1]), entschluessle(f[2]), entschluessle(f[3])));
                    }
                }
            }
            String status;
            if (lauf.zeitlimit()) {
                status = "zeitlimit";
            } else if (!tests.isEmpty() && tests.stream().allMatch(t -> t.status().equals("OK"))) {
                status = "bestanden";
            } else {
                status = "nicht_bestanden";
            }
            return new Pruefergebnis(status, List.of(), tests, lauf.ausgabe());
        } finally {
            loesche(ordner);
        }
    }

    static String ausfuehren(String code, String eingabe) throws IOException, InterruptedException {
        Path ordner = Files.createTempDirectory("javatrainer");
        try {
            Files.writeString(ordner.resolve("Main.java"), code, StandardCharsets.UTF_8);
            List<Diagnose> diagnosen = kompiliere(ordner, "Main.java");
            if (!diagnosen.isEmpty()) {
                return new Pruefergebnis("kompilierfehler", diagnosen, List.of(), "").alsJson();
            }
            Lauf lauf = starte(ordner, "Main", eingabe);
            String status = lauf.zeitlimit() ? "zeitlimit" : lauf.exitCode() == 0 ? "ok" : "absturz";
            return new Pruefergebnis(status, List.of(), List.of(), lauf.ausgabe()).alsJson();
        } finally {
            loesche(ordner);
        }
    }

    static List<Diagnose> kompiliere(Path ordner, String... dateien) throws IOException {
        JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
        DiagnosticCollector<JavaFileObject> sammler = new DiagnosticCollector<>();
        try (StandardJavaFileManager dateiManager =
                     compiler.getStandardFileManager(sammler, Locale.GERMAN, StandardCharsets.UTF_8)) {
            List<Path> pfade = new ArrayList<>();
            for (String datei : dateien) {
                pfade.add(ordner.resolve(datei));
            }
            Iterable<? extends JavaFileObject> quellen = dateiManager.getJavaFileObjectsFromPaths(pfade);
            List<String> optionen = List.of("-d", ordner.toString(), "-encoding", "UTF-8", "-nowarn",
                    "-Xlint:none", "-implicit:none");
            compiler.getTask(null, dateiManager, sammler, optionen, null, quellen).call();
        }
        List<Diagnose> fehler = new ArrayList<>();
        for (Diagnostic<? extends JavaFileObject> d : sammler.getDiagnostics()) {
            if (d.getKind() == Diagnostic.Kind.ERROR) {
                String datei = d.getSource() == null ? "" : Path.of(d.getSource().toUri()).getFileName().toString();
                fehler.add(new Diagnose(datei, d.getLineNumber(), d.getColumnNumber(), d.getMessage(Locale.GERMAN)));
            }
        }
        return fehler;
    }

    static Lauf starte(Path ordner, String klasse, String eingabe, String... argumente)
            throws IOException, InterruptedException {
        List<String> befehl = new ArrayList<>(List.of(
                Path.of(System.getProperty("java.home"), "bin", "java").toString(),
                "-Xmx256m", "-XX:+UseSerialGC", "-XX:TieredStopAtLevel=1",
                "-Dfile.encoding=UTF-8", "-Dstdout.encoding=UTF-8", "-Dstderr.encoding=UTF-8",
                "-Dsun.stdout.encoding=UTF-8", "-Dsun.stderr.encoding=UTF-8",
                "-Duser.language=de", "-cp", ordner.toString(), klasse));
        befehl.addAll(List.of(argumente));
        ProcessBuilder pb = new ProcessBuilder(befehl).directory(ordner.toFile()).redirectErrorStream(true);
        pb.environment().remove("JAVA_TOOL_OPTIONS");
        pb.environment().remove("_JAVA_OPTIONS");
        pb.environment().remove("JDK_JAVA_OPTIONS");
        Process prozess = pb.start();

        ByteArrayOutputStream puffer = new ByteArrayOutputStream();
        Thread leser = new Thread(() -> {
            try (InputStream in = prozess.getInputStream()) {
                byte[] block = new byte[8192];
                int n;
                while ((n = in.read(block)) != -1) {
                    synchronized (puffer) {
                        if (puffer.size() < Trainer.MAX_AUSGABE) {
                            puffer.write(block, 0, Math.min(n, Trainer.MAX_AUSGABE - puffer.size()));
                        }
                    }
                }
            } catch (IOException e) {
                // Prozess beendet
            }
        });
        leser.start();
        try (OutputStream in = prozess.getOutputStream()) {
            in.write(eingabe.getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            // Programm liest keine Eingabe - egal
        }
        boolean fertig = prozess.waitFor(Trainer.ZEITLIMIT_SEKUNDEN, TimeUnit.SECONDS);
        if (!fertig) {
            prozess.descendants().forEach(ProcessHandle::destroyForcibly);
            prozess.destroyForcibly();
            prozess.waitFor(2, TimeUnit.SECONDS);
        }
        leser.join(2000);
        String ausgabe;
        synchronized (puffer) {
            ausgabe = puffer.toString(StandardCharsets.UTF_8);
            if (puffer.size() >= Trainer.MAX_AUSGABE) {
                ausgabe += "\n... (Ausgabe gekürzt)";
            }
        }
        return new Lauf(ausgabe, !fertig, fertig ? prozess.exitValue() : -1);
    }

    static String entschluessle(String s) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '\\' && i + 1 < s.length()) {
                char n = s.charAt(++i);
                sb.append(n == 'n' ? '\n' : n == 't' ? '\t' : n);
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    static void loesche(Path ordner) {
        try (Stream<Path> alle = Files.walk(ordner)) {
            alle.sorted(Comparator.reverseOrder()).forEach(p -> p.toFile().delete());
        } catch (IOException e) {
            // temporärer Ordner - nicht schlimm
        }
    }
}

// ======================================================================
//  Selbsttest: Jede Vorlage muss kompilieren und darf NICHT bestehen,
//  jede Musterlösung muss ALLE Tests bestehen.
// ======================================================================

class Selbsttest {

    static boolean ausfuehren() throws Exception {
        List<Lektion> lektionen = Kurs.laden();
        List<String> kapitelNummern = Kurs.kapitel().stream().map(Kapitel::nummer).toList();
        int fehler = 0;
        int tests = 0;
        for (Lektion l : lektionen) {
            List<String> probleme = new ArrayList<>();
            if (l.text("titel").isEmpty()) {
                probleme.add("kein Titel");
            }
            if (!kapitelNummern.contains(l.kapitel())) {
                probleme.add("Kapitel " + l.kapitel() + " fehlt in kapitel.txt");
            }
            switch (l.typ()) {
                case "code" -> {
                    Pruefergebnis vorlage = Pruefer.pruefen(l.text("pruefung"), l.text("vorlage"));
                    Pruefergebnis loesung = Pruefer.pruefen(l.text("pruefung"), l.text("loesung"));
                    boolean reparieren = !l.text("reparieren").isEmpty();
                    if (vorlage.status().equals("kompilierfehler") && !reparieren) {
                        probleme.add("Vorlage kompiliert nicht: " + vorlage.diagnosen());
                    } else if (!vorlage.status().equals("kompilierfehler") && reparieren) {
                        probleme.add("Reparier-Lektion: Vorlage sollte NICHT kompilieren");
                    } else if (vorlage.bestanden()) {
                        probleme.add("Vorlage besteht schon alle Tests");
                    }
                    if (!loesung.bestanden()) {
                        probleme.add("Lösung besteht nicht: " + loesung.status() + " "
                                + loesung.diagnosen() + " " + loesung.tests().stream()
                                .filter(t -> !t.status().equals("OK")).toList());
                    }
                    tests += loesung.tests().size();
                }
                case "quiz" -> {
                    long richtige = l.text("optionen").lines().filter(z -> z.startsWith("+ ")).count();
                    long alle = l.text("optionen").lines().filter(z -> z.startsWith("+ ") || z.startsWith("- ")).count();
                    if (richtige != 1 || alle < 2) {
                        probleme.add("Quiz braucht genau eine richtige Option (+) und mindestens zwei Optionen");
                    }
                }
                case "info" -> {
                    // nur Text
                }
                default -> probleme.add("unbekannter Typ " + l.typ());
            }
            System.out.println((probleme.isEmpty() ? "  ok      " : "  FEHLER  ") + l.id()
                    + (probleme.isEmpty() ? "" : "  " + probleme));
            if (!probleme.isEmpty()) {
                fehler++;
            }
        }
        System.out.println();
        System.out.println(lektionen.size() + " Lektionen, " + tests + " Tests in Musterloesungen, "
                + fehler + " mit Problemen.");
        return fehler == 0;
    }
}
