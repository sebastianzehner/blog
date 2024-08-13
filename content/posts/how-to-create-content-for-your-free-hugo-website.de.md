+++
title = 'Wie Inhalte für deine kostenlose Hugo Webseite erstellen'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Heute zeige ich dir, wie du Inhalte für deine Hugo Webseite erstellst, wie du Menüs, Tags und Kategorien hinzufügst und wie du einige spezielle Einstellungen vornimmst.'
date = 2024-08-13T16:05:39-04:00
lastmod = 2024-08-13T16:05:39-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Webseite', 'Hugo', 'PaperMod']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true
+++

Im [ersten Teil dieser Serie](/de/posts/how-to-build-a-minimalistic-and-self-hosted-website-for-free/) haben wir unsere Hugo Webseite mit dem PaperMod Theme lokal auf unserem Computer installiert und alles so konfiguriert, dass wir nun in der Lage sind, unserer neuen Webseite einige Inhalte hinzuzufügen.

Heute zeige ich dir, wie du diesen Inhalt erstellst, wie du Menüs, Tags und Kategorien hinzufügst und wie du einige spezielle Einstellungen vornimmst.

## Erstelle Inhalte für deine neue Webseite

### Dateistruktur erklärt

Der Ordner **content** ist für Inhalte wie neue Seiten oder Blogposts.

Die Ordner **layouts** und **assets** dienen zum Überschreiben der Standard-Layouteinstellungen des installierten Themes. Für Änderungen kopiert man die Datei aus dem Theme-Layouts- oder Assets-Ordner in den Hugo-Layouts- oder Assets-Ordner und überschreibt sie dort.

In unserem Fall ist dies das PaperMod Theme und wir nehmen keine Änderungen im Ordner `/themes/PaperMod` vor. Stattdessen kopieren wir die Dateien in unseren Layouts- oder Assets-Ordner und ändern die Dateien dort. Dies wird automatisch die Standard-Layout-Einstellungen überschreiben, sobald wir unsere Webseite bereitstellen.

Der Ordner **static** ist für alle statischen Dateien wie Bilder und unsere Sprachdateien werden im Ordner **i18n** gespeichert.

Wenn wir den Hugo-Server einmal gestartet haben, finden wir auch einen Ordner **public** mit allen HTML- und CSS-Dateien unserer Webseite zur Überprüfung im Browser.

### Erstelle den ersten Blogpost

Um einen Blogpost auf der Hugo- Webseite zu erstellen, gehe zum Terminal und gib folgendes ein:

```CMD
hugo new posts/first.md
```

Es ist wichtig, sich dabei im Stammordner der Webseite zu befinden. In meinem Fall ist das der Ordner **sebastianzehner**, später habe ich diesen Ordner allerdings in **blog** umbenannt.

Zurück in Visual Studio Code öffne die neue Datei first.md zum Bearbeiten. Die Dateierweiterung .md steht für Markdown.

### Wie schreiben und formatieren

Verwende die Markdown Basic Syntax, um deine Seiten und Blogposts zu schreiben und zu formatieren. Hier sind einige Links für weitere Informationen:

- [Markdown Basic Syntax](https://www.markdownguide.org/basic-syntax/)
- [Content Management](https://gohugo.io/content-management/front-matter/)
- [PaperMod Features](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)

Dies ist nur eine Möglichkeit, um einen neuen Beitrag über die Befehlszeile zu erstellen.

Eine andere Möglichkeit wäre, direkt in Visual Studio Code eine neue Datei zu erstellen, z. B. second.md und dies wird immer eine leere Datei sein, daher kann nach dem Erstellen der Inhalt in die neue Datei kopiert oder geschrieben und gespeichert werden.

Auch Visual Studio Code ist nur eine weitere Möglichkeit, einen Editor zu verwenden. Du kannst auch jeden anderen Editor nutzen, der dir gefällt.

Ich habe mit Visual Studio Code angefangen, bin später allerdings auf [Neovim](https://neovim.io/) umgestiegen und habe einige Anpassungen vorgenommen, um ein ansprechendes und nerdiges Entwickler-Setup zu erhalten, und ich mag es genau so :sunglasses:

Vielleicht werde ich später mal einen Blogpost über Neovim schreiben.

## Menüs erstellen

Öffne die Datei `hugo.toml` und füge Code hinzu, um das Menü zu erstellen.

Hier ein Beispiel für eine einfache Menüstruktur:

```TOML
[menus]
  [[menus.main]]
    name = 'Products'
    pageRef = '/products'
    weight = 10
  [[menus.main]]
    name = 'Hardware'
    pageRef = '/products/hardware'
    parent = 'Products'
    weight = 1
  [[menus.main]]
    name = 'Software'
    pageRef = '/products/software'
    parent = 'Products'
    weight = 2
  [[menus.main]]
    name = 'Services'
    pageRef = '/services'
    weight = 20
  [[menus.main]]
    name = 'Hugo'
    pre = '<i class="fa fa-heart"></i>'
    url = 'https://gohugo.io/'
    weight = 30
    [menus.main.params]
      rel = 'external'
```

Ich verwende eine mehrsprachige Menüstruktur. Dies ist ein Beispiel für die Menüstruktur meines Blogs:

```TOML
defaultContentLanguage = 'en'
defaultContentLanguageInSubdir = true
[languages]
  [languages.en]
    languageCode = 'en-US'
    languageName = 'English'
    weight = 1
    [languages.en.menus]
        [[languages.en.menus.main]]
            name = 'Home'
            pageRef = '/'
            weight = 10
        [[languages.en.menus.main]]
            identifier = 'categories'
            name = 'Categories'
            pageRef = '/categories/'
            weight = 20
        [[languages.en.menus.main]]
            identifier = 'tags'
            name = 'Tags'
            pageRef = '/tags/'
            weight = 30
        [[languages.en.menus.main]]
            identifier = 'archives'
            name = 'Archives'
            pageRef = '/archives/'
            weight = 40
  [languages.de]
    languageCode = 'de-DE'
    languageName = 'Deutsch'
    weight = 2
    [languages.de.menus]
        [[languages.de.menus.main]]
            name = 'Start'
            pageRef = '/'
            weight = 10
        [[languages.de.menus.main]]
            identifier = 'categories'
            name = 'Kategorien'
            pageRef = '/categories/'
            weight = 20
        [[languages.de.menus.main]]
            identifier = 'tags'
            name = 'Tags'
            pageRef = '/tags/'
            weight = 30
        [[languages.de.menus.main]]
            identifier = 'archives'
            name = 'Archiv'
            pageRef = '/archives/'
            weight = 40
```

Das war zumindest der Anfang. Später habe ich noch Spanisch hinzugefügt und einige Menüs und Einstellungen geändert.

## Tags und Kategorien hinzufügen

Die Tags und Kategorien werden in der Kopfzeile jedes Beitrags oder jeder Seite festgelegt. Beispiel:

```TOML
tags = ['Hugo', 'Website', 'PaperMod']
categories = ['Tech']
```

Es ist sehr wichtig, für jede Webseite oder jeden Blogpost nur eine Kategorie zu verwenden. Du kannst stattdessen mehrere verschiedene Tags hinzufügen. Normalerweise verwende ich eine Kategorie und drei Tags innerhalb eines Beitrags oder einer Seite.

Wenn du auch so wie ich die Menüs Kategorien oder Tags verwendest, ist das nützlich, um deinen Blog zu strukturieren und die Besucher können die Seiten nach ihren jeweiligen Interessen finden und sortieren.

## Ein paar weitere spezielle Einstellungen

Wenn du BreadCrumbs, ShareButtons, ReadingTime oder PostNavLinks auf deiner Webseite anzeigen möchtest. Füge folgendes zu deiner hugo.toml Datei hinzu:

```TOML
[params]
    ShowBreadCrumbs = true
    ShowShareButtons = true
    ShowReadingTime = true
    ShowPostNavLinks = true
```

Ich verwende den Home-Info-Modus aus dem PaperMod Theme und habe dies meiner hugo.toml Datei hinzugefügt. Ich habe auch einige Social-Media-Symbole und -Links hinzugefügt, zum Beispiel für Facebook und Youtube:

```TOML
[params.homeInfoParams]
    title = 'Hello my friend...'
    content = 'Welcome to my blog. Here you will find a lot of cool information about a lot of cool stuff.'
    [[params.socialIcons]]
        name = 'facebook'
        url = 'https://www.facebook.com/yourfacebook'
    [[params.socialIcons]]
        name = 'youtube'
        url = 'https://www.youtube.com/@youryoutube'
```

Wir haben nun diverse grundlegende Konfigurationen vorgenommen und unserer neuen Webseite einige Inhalte hinzugefügt. Der nächste Schritt wäre die Bereitstellung und Veröffentlichung unserer neuen Webseite im Internet.

Im nächsten Blogpost werde ich dir daher zeigen, wie ich das mit GitHub und Netlify kostenlos gemacht habe. Bleib dran und bis bald.

Liebe Grüße Sebastian

{{< chat how-to-create-content-for-your-free-hugo-website >}}
