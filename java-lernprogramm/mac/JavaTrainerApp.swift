// Java-Trainer - macOS-App
//
// Eine schlanke SwiftUI-Hülle: Sie startet den Java-Teil des Trainers
// (Trainer.java, vorübersetzt im App-Paket) mit dem installierten JDK und zeigt
// die Lernoberfläche in einem eigenen Fenster an. Der API-Schlüssel für Claude
// liegt im macOS-Schlüsselbund.
//
// Gebaut wird die App mit mac/app-bauen.sh.

import AppKit
import Security
import SwiftUI
import WebKit

@main
struct JavaTrainerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Java-Trainer") {
            Hauptansicht()
                .frame(minWidth: 1000, minHeight: 660)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        TrainerServer.shared.starten()
    }

    func applicationWillTerminate(_ notification: Notification) {
        TrainerServer.shared.beenden()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// MARK: - Java-Teil starten und überwachen

final class TrainerServer: ObservableObject {
    static let shared = TrainerServer()

    enum Zustand {
        case startet
        case bereit(URL)
        case fehler(String)
    }

    @Published private(set) var zustand: Zustand = .startet

    private var prozess: Process?
    private var eingabe: Pipe?
    private var protokoll = ""
    private var wirdBeendet = false

    func starten() {
        guard prozess == nil else { return }
        zustand = .startet
        protokoll = ""

        guard let javaHome = Self.javaHome() else {
            zustand = .fehler("""
                Es wurde kein Java Development Kit (JDK) ab Version 17 gefunden.
                Der Java-Trainer braucht es, um deinen Code zu übersetzen und auszuführen.
                Installiere zum Beispiel Eclipse Temurin von adoptium.net und versuche es dann erneut.
                """)
            return
        }
        guard let ressourcen = Bundle.main.resourceURL?.appendingPathComponent("trainer", isDirectory: true) else {
            zustand = .fehler("Die Dateien des Trainers fehlen im App-Paket. Bitte die App mit mac/app-bauen.sh neu bauen.")
            return
        }
        let daten = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Java-Trainer", isDirectory: true)
        try? FileManager.default.createDirectory(at: daten, withIntermediateDirectories: true)

        let p = Process()
        p.executableURL = URL(fileURLWithPath: javaHome).appendingPathComponent("bin/java")
        p.arguments = ["-Djava.awt.headless=true", "-cp", "klassen:lib/*", "Trainer", "--app", "--daten", daten.path]
        p.currentDirectoryURL = ressourcen

        var umgebung = ProcessInfo.processInfo.environment
        umgebung.removeValue(forKey: "ANTHROPIC_API_KEY")
        if let schluessel = Schluesselbund.lesen() {
            umgebung["ANTHROPIC_API_KEY"] = schluessel
        }
        p.environment = umgebung

        let ausgabe = Pipe()
        let eingabe = Pipe()
        p.standardOutput = ausgabe
        p.standardError = ausgabe
        // Solange diese Eingabe offen ist, läuft der Java-Teil. Endet die App
        // (auch durch einen Absturz), schließt macOS die Pipe und Java beendet sich.
        p.standardInput = eingabe

        ausgabe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let daten = handle.availableData
            if daten.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            let text = String(decoding: daten, as: UTF8.self)
            DispatchQueue.main.async {
                self?.verarbeite(text)
            }
        }
        p.terminationHandler = { [weak self] beendet in
            DispatchQueue.main.async {
                guard let self = self, self.prozess === beendet else { return }
                self.prozessBeendet(code: beendet.terminationStatus)
            }
        }

        do {
            try p.run()
            prozess = p
            self.eingabe = eingabe
            wirdBeendet = false
        } catch {
            zustand = .fehler("Der Java-Teil konnte nicht gestartet werden: \(error.localizedDescription)")
        }
    }

    func beenden() {
        wirdBeendet = true
        try? eingabe?.fileHandleForWriting.close()
        prozess?.terminate()
    }

    func neuStarten() {
        let alt = prozess
        prozess = nil
        try? eingabe?.fileHandleForWriting.close()
        alt?.terminate()
        starten()
    }

    private func verarbeite(_ text: String) {
        protokoll += text
        if protokoll.count > 20_000 {
            protokoll = String(protokoll.suffix(20_000))
        }
        guard case .startet = zustand else { return }
        for zeile in protokoll.split(separator: "\n") where zeile.hasPrefix("JAVATRAINER_URL=") {
            let adresse = zeile.dropFirst("JAVATRAINER_URL=".count).trimmingCharacters(in: .whitespacesAndNewlines)
            if let url = URL(string: adresse) {
                zustand = .bereit(url)
            }
        }
    }

    private func prozessBeendet(code: Int32) {
        prozess = nil
        guard !wirdBeendet else { return }
        let ende = String(protokoll.suffix(4_000))
        zustand = .fehler("Der Java-Teil wurde beendet (Code \(code)).\n\n\(ende)")
    }

    /// Sucht ein JDK (mit javac): zuerst das, mit dem die App gebaut wurde,
    /// dann den Vorschlag von macOS. Eine reine JRE reicht nicht.
    static func javaHome() -> String? {
        var kandidaten: [String] = []
        if let datei = Bundle.main.resourceURL?.appendingPathComponent("trainer/jdk-pfad.txt"),
           let text = try? String(contentsOf: datei, encoding: .utf8) {
            kandidaten.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if let vorschlag = javaHomeVorschlag() {
            kandidaten.append(vorschlag)
        }
        return kandidaten.first { FileManager.default.isExecutableFile(atPath: $0 + "/bin/javac") }
    }

    /// Fragt macOS nach einer installierten Java-Version ab 17.
    static func javaHomeVorschlag() -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/libexec/java_home")
        p.arguments = ["-v", "17+"]
        let ausgabe = Pipe()
        p.standardOutput = ausgabe
        p.standardError = Pipe()
        do {
            try p.run()
        } catch {
            return nil
        }
        let daten = ausgabe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { return nil }
        let pfad = String(decoding: daten, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return pfad.isEmpty ? nil : pfad
    }
}

// MARK: - Oberfläche

struct Hauptansicht: View {
    @ObservedObject private var server = TrainerServer.shared

    var body: some View {
        ZStack {
            Color(red: 0.055, green: 0.067, blue: 0.125)
                .ignoresSafeArea()
            switch server.zustand {
            case .startet:
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Java-Trainer startet …")
                        .foregroundColor(Color.white.opacity(0.7))
                }
            case .bereit(let url):
                WebAnsicht(url: url)
            case .fehler(let meldung):
                Fehleransicht(meldung: meldung)
            }
        }
    }
}

struct Fehleransicht: View {
    let meldung: String

    var body: some View {
        VStack(spacing: 16) {
            Text("☕")
                .font(.system(size: 44))
            Text("Der Java-Trainer konnte nicht starten")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            ScrollView {
                Text(meldung)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.8))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 640, maxHeight: 260)
            HStack(spacing: 12) {
                Button("JDK herunterladen") {
                    if let url = URL(string: "https://adoptium.net/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Erneut versuchen") {
                    TrainerServer.shared.neuStarten()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(40)
    }
}

struct WebAnsicht: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> Koordinator {
        Koordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let konfiguration = WKWebViewConfiguration()
        konfiguration.userContentController.add(context.coordinator, name: "javatrainer")
        let ansicht = WKWebView(frame: .zero, configuration: konfiguration)
        ansicht.uiDelegate = context.coordinator
        ansicht.underPageBackgroundColor = NSColor(red: 0.055, green: 0.067, blue: 0.125, alpha: 1)
        ansicht.load(URLRequest(url: url))
        return ansicht
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

/// Empfängt Nachrichten der Lernoberfläche (window.webkit.messageHandlers.javatrainer).
final class Koordinator: NSObject, WKScriptMessageHandler, WKUIDelegate {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let daten = message.body as? [String: Any], let aktion = daten["aktion"] as? String else { return }
        switch aktion {
        case "schluesselSpeichern":
            if let wert = daten["wert"] as? String {
                Schluesselbund.speichern(wert)
            }
        case "schluesselLoeschen":
            Schluesselbund.loeschen()
        case "oeffnen":
            if let text = daten["url"] as? String, let url = URL(string: text), url.scheme == "https" {
                NSWorkspace.shared.open(url)
            }
        default:
            break
        }
    }

    /// Links mit target="_blank" im Standardbrowser öffnen.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, url.scheme == "https" {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
}

// MARK: - API-Schlüssel im Schlüsselbund

enum Schluesselbund {
    private static let dienst = "de.steveschumann.JavaTrainer"
    private static let konto = "anthropic-api-key"

    static func lesen() -> String? {
        let abfrage: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var ergebnis: AnyObject?
        guard SecItemCopyMatching(abfrage as CFDictionary, &ergebnis) == errSecSuccess,
              let daten = ergebnis as? Data else {
            return nil
        }
        let wert = String(decoding: daten, as: UTF8.self)
        return wert.isEmpty ? nil : wert
    }

    static func speichern(_ wert: String) {
        loeschen()
        let eintrag: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto,
            kSecAttrLabel as String: "Java-Trainer: Anthropic API-Schlüssel",
            kSecValueData as String: Data(wert.utf8),
        ]
        _ = SecItemAdd(eintrag as CFDictionary, nil)
    }

    static func loeschen() {
        let abfrage: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto,
        ]
        _ = SecItemDelete(abfrage as CFDictionary)
    }
}
