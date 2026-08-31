# Datenschutzerklärung – was fertig ist und was du tun musst

## Was fertig ist

`docs/datenschutz.html` im Projektordner – eine vollständige, für sich stehende
Seite. Inhaltlich geprüft gegen den tatsächlichen Code:

| Aussage | Beleg |
|---|---|
| keine Netzwerkverbindung | keine Treffer für `URLSession`, `URLRequest`, `http` im Quelltext |
| keine Berechtigungen | keine `UsageDescription`-Schlüssel in der Info.plist |
| keine Fremdbibliotheken | eingebunden sind nur SwiftUI, UIKit, PDFKit, Foundation, Combine |
| lokale Speicherung | eine JSON-Datei im Dokumente-Ordner der App |

## Was du noch eintragen musst

Im Abschnitt „Verantwortlicher" stehen Platzhalter. **Name, Anschrift und
E-Mail-Adresse musst du selbst einsetzen** – ich habe deine Daten bewusst nicht
eingetragen, weil die Seite öffentlich erreichbar sein wird und das deine
Entscheidung ist. Die Apple-ID, mit der die App signiert ist, lautet
`s.schumann.hockey@web.de`; ob du diese Adresse öffentlich zeigen willst,
entscheidest du.

Eine ladungsfähige Anschrift ist bei der DSGVO Pflicht. Ein Postfach genügt
nicht. Falls du das nicht privat angeben möchtest, ist die Vereinsanschrift eine
übliche Lösung – das solltest du mit dem Verein abstimmen.

## Wie daraus eine URL wird

Apple verlangt eine öffentlich erreichbare Adresse. Drei Wege:

**1. Vereinswebsite** – am einfachsten, wenn es eine gibt. Datei hochladen, die
resultierende Adresse in App Store Connect eintragen. Fertig.

**2. GitHub Pages** (kostenlos, dauerhaft, du behältst die Kontrolle)
- Konto auf github.com anlegen, falls noch keins vorhanden
- Neues Repository anlegen, z. B. `hockey-setup`
- Dein lokales Repository verbinden und hochladen:

```bash
cd ~/Desktop/Steve/Apps/EishockeyAufstellung && git remote add origin https://github.com/DEIN-NAME/hockey-setup.git
```

```bash
cd ~/Desktop/Steve/Apps/EishockeyAufstellung && git add -A && git commit -m "App Store Vorbereitung" && git push -u origin main
```

- Im Repository unter Settings → Pages als Quelle „main" und Ordner „/docs" wählen
- Nach wenigen Minuten erreichbar unter
  `https://DEIN-NAME.github.io/hockey-setup/datenschutz.html`

**3. Jeder andere Webspace** – die Datei ist eine einzelne HTML-Seite ohne
Abhängigkeiten und läuft überall.

## Wichtiger Hinweis

Ich bin kein Anwalt, und das hier ist keine Rechtsberatung. Der Text beschreibt
das tatsächliche Verhalten der App korrekt und deckt die üblichen Punkte ab.
Ob er für deinen Fall vollständig ist – etwa hinsichtlich Impressumspflicht nach
dem Digitale-Dienste-Gesetz – solltest du prüfen oder prüfen lassen. Für eine
App ohne jede Datenerhebung ist das Risiko gering, aber die Entscheidung liegt
bei dir.
