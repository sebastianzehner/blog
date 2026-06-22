---
title: 'Von PaperMod zu Blowfish: Warum ich mein Hugo Theme gewechselt habe'
summary: >-
  Nach Jahren mit PaperMod habe ich mein Hugo Blog auf Blowfish umgestellt. Was
  mich überzeugt hat, was anders ist und warum Catppuccin dabei eine Rolle
  spielt.
date: 2026-06-22T21:25:07.000Z
lastmod: 2026-06-22T21:25:07.000Z
tags:
  - hugo
  - blowfish
  - blogging
  - website
  - catppuccin
categories:
  - techlab
showComments: true
chatId: blowfish
---
Wer meinen Blog schon länger kennt, wird den Wechsel vielleicht gar nicht
sofort bemerkt haben und genau das ist eigentlich ein gutes Zeichen. Die
Inhalte sind dieselben, die URLs ebenfalls. Was sich verändert hat, ist das
Fundament darunter: **das Hugo Theme**.

Lange Zeit lief dieser Blog mit:

{{< github repo="adityatelange/hugo-PaperMod" showThumbnail=true >}}

Einem schlanken, schnellen und weit verbreiteten Theme für [Hugo](https://gohugo.io/).

PaperMod hat seinen Job gut gemacht und ich war damit auch zufrieden. Im Laufe
der Zeit hatte ich einiges angepasst und erweitert. Ein Hugo Update hatte
außerdem einige Änderungen an den Language Parametern mit sich gebracht, die
ich anpassen musste.

Zufällig stieß ich dann auf Blowfish und was ich dort sah, sprach mich sofort
an. Nicht weil PaperMod schlecht war, sondern weil Blowfish einige nützliche
Funktionen mitbringt, die direkt der Benutzerfreundlichkeit des Blogs zugute
kommen und die ich bei PaperMod selbst hätte nachbauen müssen.

## Was mich an Blowfish überzeugt hat

[Blowfish][1] ist ein modernes Hugo Theme von [Nuno Coração][2], das auf
Tailwind CSS aufbaut und optisch deutlich moderner wirkt als PaperMod.
Aber nicht nur das Aussehen hat mich überzeugt, sondern überwiegend die
Features, die im Alltag wirklich einen Unterschied machen.

**GitHub-style Alerts** direkt in Markdown und das ohne eigene Shortcodes:

> [!NOTE]
> So sieht eine Notiz aus, direkt in Markdown geschrieben.

Bei PaperMod hätte ich dafür einen eigenen Shortcode und CSS schreiben müssen.
Bei Blowfish tippe ich einfach `> [!NOTE]` und fertig.

**Repo-Karten** für GitHub, Forgejo und Codeberg, **Icon-Support**,
**eingebaute Suche** als Overlay, **Zen-Modus** zum ablenkungsfreien Lesen,
**Barrierefreiheits-Einstellungen** (Schriftgröße, Blur, Links unterstreichen) und
all das bringt Blowfish von Haus aus mit, ohne dass ich selbst Hand anlegen
muss.

Dazu kommt eine sehr aktive Community und eine [Dokumentation][3],
die wirklich gut ist.

{{< github repo="nunocoracao/blowfish" showThumbnail=true >}}

## Die Migration war mehr Arbeit als gedacht aber es lohnt sich

Ich wäre unehrlich, wenn ich sagen würde, die Migration war einfach. Blowfish
hat eine andere Konfigurationsstruktur als PaperMod, denn statt einer einzigen
`hugo.yaml` gibt es mehrere Dateien unter `config/_default/`:

```bash
config/_default/
├── hugo.toml
├── languages.de.toml
├── languages.en.toml
├── languages.es.toml
├── markup.toml
├── menus.de.toml
├── menus.en.toml
├── menus.es.toml
└── params.toml
```

Das klingt zunächst nach mehr Aufwand aber ist auf lange Sicht deutlich
übersichtlicher, besonders bei einem mehrsprachigen Blog wie meinem.

Die eigentliche Fleißaufgabe war die Migration aller Beiträge auf
**Page Bundles**: Statt einzelner `.md`-Dateien bekommt jeder Artikel seinen
eigenen Ordner mit `index.md`, `index.de.md`, `index.es.md` und allen
zugehörigen Bildern direkt daneben. Das macht das Projekt insgesamt viel
aufgeräumter.

```bash
content/posts/my-blogpost/
├── background.webp
├── featured.webp
├── index.de.md
├── index.es.md
└── index.md
```

## Was ich selbst gebaut hatte und was Blowfish einfach mitbringt

Bei PaperMod war ich nicht mit dem Standard zufrieden und hatte im Laufe der
Zeit einiges selbst nachgebaut oder angepasst: ein erweitertes Inhaltsverzeichnis
(TOC), eine Series-Funktion für mehrteilige Artikel und die Integration von
[Cactus Comments][5], dem datenschutzfreundlichen Kommentarsystem auf Basis
von Matrix.

Blowfish bringt TOC und Series bereits von Haus aus mit, alles konfigurierbar
über `params.toml`, kein eigener Template-Code nötig. Das hat mir einige
selbstgebaute Partials erspart, die ich nach der Migration einfach löschen
konnte.

Cactus Comments habe ich weiterhin im Einsatz, weil es perfekt zu meinem
selbst gehosteten [Matrix Homeserver][6] passt. Die Integration läuft jetzt über
Blowfishs offiziellen `comments.html`-Hook, das sogar sauberer als vorher, und ich
konnte dabei gleich ein Update auf die neue Cactus-Version einspielen, die
Mehrsprachigkeit und `isAuthenticated` unterstützt.

**Letzteres war besonders wichtig:** Auf Synapse-Seite konnte ich dadurch
`enable_authenticated_media: true` wieder aktivieren, was die Mediensicherheit
deutlich verbessert.

## Catppuccin als Farbschema

Wer meinen Blog kennt, weiß, dass [Catppuccin][4] meine favorisierte Palette ist,
sowohl im Terminal, in Neovim als auch bei meinem Blog. Blowfish unterstützt
eigene Color Schemes über eine einfache CSS-Datei unter
`assets/css/schemes/catppuccin.css`.

**Das Besondere:** Blowfish nutzt Tailwind CSS mit CSS-Variablen für alle Farben.
Damit lässt sich Catppuccin Latte (Light Mode) und Catppuccin Mocha (Dark Mode)
sauber abbilden:

- `--color-neutral-*` für die Hintergrund- und Textfarben
- `--color-primary-*` für Blau (Links, Buttons)
- `--color-secondary-*` für Mauve (Inline-Code, Badges)

Das Ergebnis ist ein Blog, der sich in meiner gesamten Linux-Umgebung zu Hause
fühlt.

## Was ich vermisse

**Ehrlichkeit gehört dazu:** PaperMod war schneller. Es ist ein minimalistisches
Theme ohne viel Overhead, und das merkt man an den Build-Zeiten und am
Seitengewicht. Blowfish bringt mehr JavaScript und CSS mit, das ist nichts
Dramatisches, aber sollte erwähnt werden.

Außerdem ist Blowfish auf Tailwind aufgebaut, was bedeutet: Wer eigene
Anpassungen machen will, muss die Tailwind-Klassen kennen oder bereit sein,
etwas zu lernen. Das ist kein Nachteil, aber ein Unterschied zu PaperMod,
wo man einfach CSS-Variablen überschreiben konnte.

## Fazit

Der Wechsel hat sich gelohnt. Blowfish ist optisch moderner, feature-reicher
und macht vieles möglich, das ich bei PaperMod selbst hätte bauen müssen. Die
Migration war aufwendig, aber es hat sich gelohnt und der Blog steht jetzt auf
einem soliden Fundament.

Wer Hugo nutzt und über ein Theme nachdenkt, dem empfehle ich, einen Blick auf
[blowfish.page][1] zu werfen. Die Demo-Seite zeigt viele der Features live,
und der Einstieg ist mit der ordentlichen Dokumentation gut machbar.

Falls du Fragen zur Migration oder zur Catppuccin-Anpassung hast, schreib
gerne einen Kommentar!

Liebe Grüße  
Sebastian

[1]: https://blowfish.page/
[2]: https://github.com/nunocoracao
[3]: https://blowfish.page/docs/
[4]: https://catppuccin.com/
[5]: /posts/cactus-comments-blog-comments-matrix-server/
[6]: /posts/self-hosting-matrix-homeserver-synapse/

