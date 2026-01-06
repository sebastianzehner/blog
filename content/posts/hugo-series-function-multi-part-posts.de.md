---
title: "Hugo: Serien-Funktion für mehrteilige Blogposts"
summary: "Passend zu meiner geplanten Blog-Serie habe ich eine Serien-Funktion in Hugo integriert. In diesem Tutorial zeige ich dir, wie du mehrteilige Beiträge mit automatischer Nummerierung und Navigation erstellst."
date: 2026-01-04T21:35:10-03:00
lastmod: 2026-01-04T21:35:10-03:00
draft: false
tags:
  - hugo
  - blogging
  - markdown
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/hugo-series-function-multi-part-posts.webp
  alt: "Hugo: Serien-Funktion für mehrteilige Blogposts"
  hidden: false
  relative: false
  responsiveImages: false
---

Wer kennt das nicht? Manchmal reicht ein einziger Blogpost einfach nicht aus, um ein Thema in der Tiefe zu behandeln. Man schreibt eine mehrteilige Artikelserie – doch wie finden sich die Leser zurecht? Standardmäßig bietet Hugo zwar Kategorien und Tags, aber keine native Anzeige für Artikelserien, die den Fortschritt und die Reihenfolge visualisiert.

Kürzlich habe ich dieses Problem für meinen Blog gelöst und eine Serien-Funktion implementiert. In dieser Anleitung zeige ich dir, wie du das mit Hugo-Bordmitteln ganz einfach selbst umsetzen kannst.

## Warum eine Serien-Funktion?

Wenn ein Leser einen Teil einer Serie findet, möchte er meistens drei Dinge wissen:

1. Dass dieser Post Teil einer größeren Reihe ist.
2. Welchen Teil er gerade liest (z.B. Teil 2 von 5).
3. Wo die Links zu den anderen Teilen der Serie sind.

## Schritt 1: Die Serie in Hugo registrieren

Zuerst müssen wir Hugo mitteilen, dass es neben Tags und Kategorien nun auch "Serien" gibt. Ergänze dazu deine `hugo.yaml` wie folgt:

```yaml
taxonomies:
  categories: categories
  tags: tags
  series: series
```

## Schritt 2: Das Partial erstellen

Wir erstellen ein "Partial", also einen wiederverwendbaren Code-Baustein. Erstelle die Datei `layouts/partials/series.html` und füge folgenden Code ein:

```html
{{ $series := .GetTerms "series" }}
{{ if $series }}
    {{ range $series }}
    {{ $posts := .Pages.ByDate }}
    {{ $count := len $posts }}
    <aside class="series-container">
        <details {{ if lt $count 5 }}open{{ end }}>
            <summary class="series-summary">
                <div class="series-header-text">
                    <span class="series-title">
                        {{ i18n "series_title" }}: {{ .Name }}
                    </span>
                    <span class="series-count">
                        {{ i18n "series_parts_total" $count }}
                    </span>
                </div>
            </summary>
            <ul class="series-list">
                {{ range $num, $post := $posts }}
                    {{ $isCurrent := eq $post.Permalink $.Page.Permalink }}
                    <li class="series-item">
                        <span class="series-part-label">
                            {{ i18n "series_part" }} {{ add $num 1 }}
                        </span>
                        {{ if $isCurrent }}
                            <span class="series-item-current" aria-current="page">
                                 {{ i18n "series_current" }}
                            </span>
                        {{ else }}
                            <a href="{{ $post.Permalink }}" class="series-item-link">
                                {{ .Params.series_title | default .Title }}
                            </a>
                        {{ end }}
                    </li>
                {{ end }}
            </ul>
        </details>
    </aside>
    {{ end }}
{{ end }}
```

**Der Code im Detail:**

- **Wir starten mit `.GetTerms "series"`:** Dieser Befehl greift auf die Taxonomie zu. Falls ein Artikel mehreren Serien zugeordnet ist, würde der Code dank der anschließenden `range`-Schleife für jede Serie eine eigene Box rendern.

- **Die Sortierung (`.Pages.ByDate`):** Standardmäßig liefert Hugo Seiten oft nach Gewichtung oder Datum absteigend. Mit `.ByDate` stellen wir sicher, dass die Serie logisch von vorne nach hinten (Teil 1, 2, 3...) aufgelistet wird.

- **Dynamischer Status der Box:** Das ist ein schönes Komfort-Feature. Ist die Serie kurz (weniger als 5 Teile), bleibt die Box offen. Bei sehr langen Serien klappt sie sich ein, um den Lesefluss nicht zu unterbrechen.
```html
<details {{ if lt $count 5 }}open{{ end }}>
```

- **Automatisierte Nummerierung:** Wir müssen die Nummer des Teils nicht manuell im Frontmatter pflegen. Hugo nutzt hier den Index der Schleife (der bei 0 startet) und rechnet einfach `+ 1`.
```html
{{ range $num, $post := $posts }} ... {{ add $num 1 }}
```

- **Sprache mit `i18n`:** Damit die Texte (wie "Teil 1") in verschiedenen Sprachen funktionieren, nutzen wir Hugos Internationalisierungs-Funktion.

- **Flexibles Titel-Handling:** Hier nutzen wir eine Pipe: Wenn im Artikel ein spezieller `series_title` (z. B. ein kürzerer Titel für die Liste) definiert ist, wird dieser genommen. Falls nicht, greift Hugo automatisch auf den normalen `.Title` zurück.
```html
{{ .Params.series_title | default .Title }}
```

- **Logik für den aktuellen Post:** Der Code prüft, ob der Link in der Liste der aktuelle Beitrag ist (`$isCurrent`). Wenn ja, wird er hervorgehoben und ist nicht anklickbar.

## Schritt 3: Integration im Template

Damit die Box auch angezeigt wird, musst du das Partial in dein Single-Post-Template einbauen (meist `layouts/_default/single.html`). Ich habe es direkt vor dem Content platziert:

```html
{{ partial "series.html" . }}
<div class="post-content">
  {{ .Content }}
</div>
```

## Schritt 4: Sprachdateien und Styling

Damit die Begriffe korrekt übersetzt werden, füge dies zu deinen `i18n`-Dateien mit der entsprechenden Sprachen hinzu:

```yaml
- id: series_part
  translation: "Teil"
- id: series_title
  translation: "Dieser Artikel ist Teil der Serie"
- id: series_current
  translation: "Aktueller Beitrag"
- id: series_parts_total
  translation:
    one: "Teil insgesamt"
    other: "{{ .Count }} Teile insgesamt"
```

Vergiss nicht, in deiner `post-single.css` noch etwas Styling hinzuzufügen, damit die Box optisch zu deinem Blog passt (z. B. Abstände, Rahmen oder Hintergrundfarben).

## Anwendung im Blogpost (Frontmatter)

Um einen Post einer Serie zuzuordnen, ergänzt du einfach das Frontmatter deines Artikels:

```ini
series:
  - Roadtrip Spanien und Portugal
# Optionaler kürzerer Titel für die Liste
series_title: Camping mit dem Wohnmobil durch Spanien und Portugal
```

## Ausblick: Was kommt als Nächstes?

Ich habe die Funktion direkt genutzt, um meine [vier älteren Beiträge zum Roadtrip durch Spanien und Portugal](/de/posts/road-trip-trough-spain-and-portugal-in-a-motorhome-part-1/) neu zu organisieren. Schaut sie euch gerne mal an!

Der eigentliche Grund für diesen Umbau ist jedoch ein weiteres Projekt, welches demnächst startet. Eine neue, umfangreiche Serie zum Thema **"Freiheit bei E-Mails"**.

Es wird darum gehen, ob und wie man sich von großen Anbietern lösen kann und welche Alternativen es zum Selbsthosten im eigenen Homelab gibt. Das Ganze wird nicht nur technisch, sondern auch ein wenig philosophisch. Haben wir unsere Freiheit bei E-Mail schon verloren?

Dank der neuen Serien-Funktion behaltet ihr dabei hoffentlich immer den Überblick! Alle meine Serien findet ihr ab sofort unter [Serien](/de/series), was übrigens auch auf der [Übersichtsseite](/de/overview/) verlinkt ist.

**Was denkt ihr?** Nutzt ihr selbst auch Serien für eure Blogs oder reicht euch die klassische Tag-Cloud? Schreibt es mir gerne in die Kommentare.

Ich freue mich auf euer Feedback!

{{< chat hugo-series-function >}}
