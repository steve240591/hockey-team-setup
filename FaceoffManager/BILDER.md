# Bildliste für die KI-Grafiken

Im ersten Entwurf stehen überall Platzhalter. Sobald ein Bild mit dem **exakten Namen** in
`Assets.xcassets` liegt, verwendet das Spiel es automatisch. Am Code muss nichts geändert werden.

## So fügst du ein Bild ein

1. In Xcode `Assets.xcassets` öffnen.
2. Die PNG-Datei hineinziehen.
3. Den Eintrag exakt wie in der Spalte „Name“ benennen (Kleinschreibung beachten).
   Ausnahme App-Symbol: das Bild in den vorhandenen Eintrag `AppIcon` ziehen.

## Einheitlicher Stil

Damit alle Bilder zusammenpassen, beginnt jeder Prompt mit diesem Stil-Satz:

> Flat 2D cartoon game asset, ice hockey theme, bold dark outlines, soft shading, friendly and colorful,
> icy blue and white palette with red accents, centered, transparent background, no text, no letters,
> no logos, no real team names or brands.

Wichtig wegen Lizenzen: keine echten Vereinslogos, Trikots, Ligen oder Spielergesichter erzeugen lassen.

## Bilder

| Name | Größe (PNG) | Wo im Spiel | Prompt (nach dem Stil-Satz) |
| --- | --- | --- | --- |
| `AppIcon` | 1024 × 1024, **ohne** Transparenz | App-Symbol | A cheerful cartoon yeti hockey player holding a stick, puck in front, on an ice rink background with a stadium glow. Fill the whole square, no transparent areas. |
| `icon_coin` | 256 × 256 | Münzanzeige oben | A shiny gold coin with a small hockey stick and puck embossed on it. |
| `facility_ticket` | 512 × 512 | Ticketschalter | A small wooden ticket booth next to a frozen pond, with a striped awning. |
| `facility_food` | 512 × 512 | Imbissstand | A cozy snack stand with steaming hot drinks and pretzels, winter setting. |
| `facility_shop` | 512 × 512 | Fanshop | A small fan shop with scarves, jerseys and foam fingers in fictional colors. |
| `facility_training` | 512 × 512 | Trainingshalle | An indoor training hall with dumbbells, a hockey net and cones. |
| `facility_stands` | 512 × 512 | Tribünen | Rows of stadium grandstand seats filled with cheering cartoon fans. |
| `facility_sponsor` | 512 × 512 | Sponsorenbüro | A modern office desk with a briefcase, contract papers and a handshake. |
| `facility_vip` | 512 × 512 | VIP-Logen | A luxurious glass VIP box overlooking an ice rink, with a golden star. |
| `facility_academy` | 512 × 512 | Nachwuchsakademie | Young hockey players in training with a coach and a whistle. |
| `facility_videocube` | 512 × 512 | Videowürfel und Lichtshow | A big jumbotron video cube hanging over an ice rink with colorful spotlights. |
| `player_goalie` | 512 × 512 | Spielerliste, Torhüter | A cartoon hockey goalie in full gear with big pads and a mask, generic red and white kit. |
| `player_defense` | 512 × 512 | Spielerliste, Verteidiger | A sturdy cartoon hockey defenseman skating backwards, generic blue and white kit. |
| `player_forward` | 512 × 512 | Spielerliste, Stürmer | A fast cartoon hockey forward taking a slap shot, generic blue and white kit. |
| `penalty_goalie` | 512 × 560 | Minispiel, Torwart | Front view of a cartoon hockey goalie crouching in the ready position, wide pads, viewed from the shooter's perspective. |
| `penalty_puck` | 128 × 128 | Minispiel, Puck | A black hockey puck seen from above, slight shine. |

## Später (noch nicht im Spiel verwendet)

Diese Bilder kann ich einbauen, sobald sie da sind:

- Maskottchen für die 15 Gegnerteams (Yeti, Elch, Pinguin, Walross …), je 512 × 512
- Hintergrund für das Penalty-Schießen (Eisfläche von oben mit Tor), 1290 × 2796
- Screenshots und Video für die App-Store-Seite
