+++
title = 'Wie man eine einfache und selbst gehostete Webseite kostenlos erstellt'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Du bist hier auf meiner neuen minimalistischen und kostenlosen Webseite. Ich habe diese Webseite vor einigen Wochen erstellt, weil ich es gerne einfach habe und daher WordPress durch Hugo und das PaperMod Theme für meinen persönlichen Blog im Internet ersetzt.'
date = 2024-07-22T10:29:42-04:00 #Ctrl+Shift+I to insert date and time
lastmod = 2024-07-22T10:29:42-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Webseite', 'Hugo', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true
+++

Du bist hier auf meiner neuen minimalistischen und kostenlosen Webseite. Ich habe diese Webseite vor einigen Wochen erstellt, weil ich es gerne einfach habe und daher WordPress durch Hugo und das PaperMod Theme für meinen persönlichen Blog im Internet ersetzt. Ich habe einige ältere Blogbeiträge umgezogen und bereits neue Beiträge auf dieser Plattform geschrieben. Es ist wirklich schön und ich mag es - es ist kostenlos und Open Source.

Heute möchte ich dir zeigen, wie du eine minimalistische und selbst gehostete Webseite kostenlos erstellen kannst - wie ich es gemacht habe. Ich habe Hugo auf einem Mac Studio installiert, aber es funktioniert auch auf Linux- oder Windows-Rechnern. Das gefällt mir so gut, dass ich eine zweite Hugo-Seite mit dem Smol-Theme für mein Intranet zu Hause erstellen werde.

Aber nun zur Installation und den ersten Schritten:

## Visual Studio Code herunterladen und installieren

Ich verwende Visual Studio Code auf meinem Mac Studio, um alle meine Projekte zu schreiben und zu konfigurieren. Diese Anwendung ist Open Source und funktioniert auch auf anderen Systemen. Ich habe die Mac-Version heruntergeladen und die Datei einfach entpackt und in den Anwendungsordner verschoben. Das war's und jetzt können wir Visual Studio Code mit einem einfachen Mausklick auf die App starten.

Außerdem kann ich meine Webseite mit Visual Studio Code auf GitHub synchronisieren und veröffentlichen.

Das ist alles kostenlos und du kannst deine Webseite direkt auf GitHub hosten und eine URL erstellen oder Netlify benutzen, so wie ich es mache. Vielleicht erzähle ich dir später, wie das funktioniert. Zuerst kannst du Visual Studio Code [hier](https://code.visualstudio.com/) herunterladen.

## Homebrew auf dem Mac installieren

Der einfachste Weg, Hugo zu installieren, ist die Verwendung des Paketmanagers Homebrew.

Übrigens funktioniert das auch für andere Linux-Maschinen. Ich habe den Befehl von der [Webseite](https://brew.sh/) kopiert und in die Terminal-Befehlszeile auf meinem Mac eingefügt. Die Installation wurde automatisch abgeschlossen. Die Command Line Tools für Xcode werden mit diesem Befehl ebenfalls automatisch installiert.

Nachdem die Installation abgeschlossen ist, führe zwei Befehle in deinem Terminal aus, um Homebrew zu deinem PATH hinzuzufügen. Sie sind hinter "next steps" im Terminal aufgelistet. Du kannst sie einfach kopieren und einfügen.

Um die Homebrew-Analysen zu deaktivieren, verhindert dieser Befehl, dass die Analysen jemals gesendet werden:

`brew analytics off`

Überprüfe die installierte Version mit:

`brew -v`

In meinem Fall: Homebrew 4.3.8

## Installiere Hugo mit dem Open-Source-Paketmanager Homebrew

Diese Installation ist sehr einfach. Du kannst [hier](https://gohugo.io/installation/macos/) eine Dokumentation finden.

Wie bereits erwähnt, habe ich den Paketmanager Homebrew für MacOS verwendet und die erweiterte Version von Hugo mit dem folgenden Befehl im Terminal installiert:

`brew install hugo`

Das ist alles - Hugo ist jetzt installiert.

## Erstelle eine neue Webseite mit Hugo

Auf meinem System habe ich einen neuen Ordner `MyHugoWebsites` in meinem `Documents`-Ordner erstellt und in der Kommandozeile zu diesem Ordner gewechselt.

Meine neue Webseite heißt `sebastianzehner` und mit dem folgenden Befehl habe ich diese neue Webseite erstellt:

`hugo new site sebastianzehner`

Es ist möglich, verschiedene Konfigurationsdateien wie YAML oder TOML zu erstellen. Ich habe die Standardkonfiguration mit der TOML-Konfigurationsdatei verwendet.

Ich habe [hier](https://transform.tools/yaml-to-toml) eine Webseite gefunden, die YAML in TOML umwandelt. Manchmal hilft es auch, wenn du ein Tutorial liest und dort andere Konfigurationsdateien verwendet werden. Ich verwende immer TOML für meine Seiten.

## Installiere ein Theme für Hugo

Ich habe mich entschieden, das Theme [PaperMod](https://themes.gohugo.io/themes/hugo-papermod/) als schnelles, sauberes, reaktionsschnelles Hugo-Theme zu verwenden. Eine Dokumentation für die Installation findest du [hier](https://github.com/adityatelange/hugo-PaperMod/wiki/Installation).

Ich benutzte den folgenden Befehl im Terminal und wechselte zu meinem Webseiten-Ordner `sebastianzehner`:

`git clone https://github.com/adityatelange/hugo-PaperMod themes/PaperMod –depth=1`

Nun wird das PaperMod-Theme heruntergeladen und im Theme-Ordner der lokalen Webseite gespeichert.

Für mein lokales Intranet werde ich das Theme [Smol](https://github.com/colorchestra/smol) verwenden. Der Installationsvorgang ist derselbe. Mein Intranet ist auf einem Raspberry Pi installiert.

## Hugo Webseite konfigurieren

In der Suchleiste von Visual Studio Code: *> install Shell Command: Install code command in PATH*

Gib dann im Terminal ein: `code .` und Visual Studio Code wird mit dem installierten Webseite-Pfad geöffnet.

Öffne `hugo.toml` und bearbeite die Konfiguration. Ich habe folgendes geändert:

```
baseURL = 'localhost'
languageCode = 'en-us'
title = 'My new Hugo website'
theme = 'PaperMod'
```

Danach gebe den folgenden Befehl in das Terminal ein, um den lokalen Entwicklungs-Webserver zu starten:

`hugo server`

Das Ergebnis wird wie folgt aussehen: `Web Server is available at //localhost:1313/`

Nun läuft meine Webseite lokal auf meinem Mac Studio als Serverdienst und aktualisiert alle Änderungen umgehend. Drücke `Strg+C` um den Server bei Bedarf zu stoppen oder deine Arbeit zu beenden. **Das war auch eine sehr einfache Installation!**

In meinem nächsten Blogbeitrag werde ich dir zeigen, wie du Inhalte für deine neue Webseite erstellen kannst. Wie man ein Menü hinzufügt, Tags und Kategorien, einige spezielle Einstellungen usw.

Liebe Grüße Sebastian

{{< chat how-to-build-a-minimalistic-and-self-hosted-website-for-free >}}

