---
title: "Cactus Comments – Blogkommentare über den eigenen Matrix-Server"
summary: Wie ich mit Cactus Comments ein dezentrales, trackingfreies Kommentarsystem auf Basis meines eigenen Matrix-Servers in meinen Hugo-Blog integriert habe – inklusive Client-Build, Appservice-Setup und Catppuccin-Styling.
date: 2026-04-18T17:10:00-03:00
lastmod: 2026-04-18T17:10:00-03:00
draft: false
tags:
  - matrix
  - cactus
  - homeserver
  - hugo
  - synapse
  - open-source
  - self-hosting
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/cactus-comments-cover.webp
  alt: Cactus Comments
  hidden: false
  relative: false
  responsiveImages: false
---

*Kommentarsysteme wie Disqus sind praktisch – aber sie laden Tracking, Werbung und externe Abhängigkeiten mit. Cactus Comments macht das anders: Kommentare landen direkt in Matrix-Räumen auf dem eigenen Homeserver.*
 
Im [letzten Artikel](https://sebastianzehner.com/de/posts/self-hosting-matrix-homeserver-synapse/) habe ich gezeigt, wie man Synapse mit Docker aufsetzt und einen eigenen Matrix-Homeserver betreibt. Heute bauen wir darauf auf: Mit **Cactus Comments** bekommt jeder Blogartikel seinen eigenen Matrix-Chatraum – Leser können Kommentare hinterlassen, ohne sich bei einem Drittanbieter registrieren zu müssen, und ich habe die volle Kontrolle über meine Daten.

## Was ist Cactus Comments?
 
[Cactus Comments](https://cactus.chat/) ist ein föderiertes Kommentarsystem für das offene Web, das das Matrix-Protokoll als Backend nutzt. Das Prinzip ist elegant: Für jeden Blogartikel wird automatisch ein Matrix-Raum angelegt. Wer einen Kommentar schreiben möchte, meldet sich mit seinem Matrix-Account an – das kann ein Account auf `matrix.org`, meinem eigenen Server oder jedem anderen Matrix-Homeserver sein. Federation sei Dank.
 
Das System besteht aus zwei Teilen:
 
- **Cactus Appservice** – ein Python-Dienst, der als Matrix-Bot (hier: `@cactusbot`) auf dem Homeserver läuft und die Räume verwaltet
- **Cactus Client** – eine JavaScript/Elm-Webanwendung, die auf dem Blog eingebettet wird und das Kommentarfeld rendert

## Voraussetzungen
 
- Ein laufender Synapse-Homeserver (meine Anleitung dazu: [eigener Matrix-Homeserver mit Synapse](https://sebastianzehner.com/de/posts/self-hosting-matrix-homeserver-synapse/))
- Docker und Docker Compose
- Node.js und npm (für den Client-Build)
- Eine Hugo-Website


## Den Cactus Client bauen
 
Der Cactus Client wird nicht als fertige Bundle-Datei ausgeliefert – er muss selbst gebaut werden. Ich möchte außerdem eine eigene Kopie im lokalen Forgejo behalten, statt mich auf GitLab zu verlassen.
 
**Repository klonen und auf Forgejo spiegeln:**
 
```bash
git clone https://gitlab.com/cactus-comments/cactus-client.git
cd cactus-client
 
git remote rename origin gitlab
git remote add origin https://git.techlab.icu/sebastianzehner/cactus-client.git
 
git push origin --all
git push origin --tags
```
 
**Build ausführen:**
 
```bash
npm install
npm run build
```

> Wenn du noch kein eigenes Forgejo hast, kannst du das Spiegeln überspringen.

### Möglicher Fehler: Korruptes Elm-Paket
 
Beim ersten Build-Versuch ist bei mir folgender Fehler aufgetaucht:
 
```
🚨  CORRUPT PACKAGE DATA
I downloaded the source code for ryannhg/date-format 2.3.0 from:
    https://github.com/ryannhg/date-format/zipball/2.3.0/
But it looks like the hash of the archive has changed since publication.
```
 
Das Paket `ryannhg/date-format` hat seit seiner Veröffentlichung einen geänderten Hash – ein bekanntes Problem bei Elm-Abhängigkeiten, wenn der Paketautor den Version-Tag nachträglich verschoben hat. Die Lösung: das Paket manuell herunterladen und an der richtigen Stelle ablegen.
 
```bash
cd ~/.elm/0.19.1/packages/ryannhg/date-format/2.3.0/
curl -L "https://github.com/ryannhg/date-format/zipball/2.3.0/" -o package.zip
unzip package.zip
mv ryan-haskell-date-format-b0e7928/* .
rm -rf ryan-haskell-date-format-b0e7928 package.zip
```
 
Danach nochmal bauen – diesmal erfolgreich:
 
```
✨  Built in 3.73s.
 
dist/cactus.js        155.95 KB
dist/style.css          6.96 KB
```

## Den Appservice einrichten
 
### Schritt 1: Tokens generieren
 
Der Appservice benötigt zwei zufällige Tokens für die Authentifizierung zwischen Synapse und Cactus:
 
```bash
cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 2
```
 
Die erste Ausgabezeile wird `as_token`, die zweite `hs_token`. Beide gut notieren.

### Schritt 2: Registration-Datei für Synapse erstellen
 
```bash
nvim ~/docker/synapse/files/cactus.yaml
```

Inhalt:

```yaml
id: "Cactus Comments"
 
url: "http://cactus:5000"
 
as_token: "YOUR_AS_TOKEN"
hs_token: "YOUR_HS_TOKEN"
 
sender_localpart: "cactusbot"
 
namespaces:
  aliases:
    - exclusive: true
      regex: "#comments_.*"
```
 
Diese Datei teilt Synapse mit, dass es einen Appservice namens `cactusbot` gibt, der alle Raumaliase mit dem Präfix `#comments_` verwaltet.

### Schritt 3: homeserver.yaml ergänzen
 
```bash
nvim ~/docker/synapse/files/homeserver.yaml
```
 
Folgende Zeilen hinzufügen:
 
```yaml
app_service_config_files:
  - "/data/cactus.yaml"
 
allow_guest_access: true
use_appservice_legacy_authorization: true
enable_authenticated_media: false
 
public_baseurl: "https://matrix.your-domain.com"
```
 
> **Wichtig:** Der Pfad `/data/cactus.yaml` ist der Pfad *innerhalb* des Synapse-Containers. Bei mir ist `~/docker/synapse/files/` als `/data` gemountet.

> **Sicherheitshinweis:** Die Einstellungen `allow_guest_access: true`, `use_appservice_legacy_authorization: true` und `enable_authenticated_media: false` sind Anforderungen des Cactus Appservice und lockern einige Sicherheitseinstellungen von Synapse. Wer das vermeiden möchte, müsste den Cactus Client entsprechend erweitern – das liegt jedoch außerhalb des Rahmens dieser Anleitung.

### Schritt 4: Umgebungsvariablen für Cactus
 
```bash
nvim ~/docker-compose/synapse/cactus.env
```

Inhalt:

```env
CACTUS_HS_TOKEN=YOUR_HS_TOKEN
CACTUS_AS_TOKEN=YOUR_AS_TOKEN
CACTUS_HOMESERVER_URL=http://synapse:8008
CACTUS_USER_ID=@cactusbot:matrix.your-domain.com
```

### Schritt 5: Docker Compose erweitern
 
In der bestehenden `docker-compose.yml` für Synapse füge ich den Cactus-Service hinzu:
 
```yaml
  cactus:
    image: cactuscomments/cactus-appservice:latest
    container_name: cactus
    env_file: cactus.env
    restart: unless-stopped
    networks:
      - synapse
```
 
Cactus landet im `synapse`-Netzwerk, damit es den Synapse-Container direkt unter `http://synapse:8008` erreichen kann.

### Schritt 6: Starten
 
```bash
cd ~/docker-compose/synapse
docker compose down
docker compose up -d synapse
# wait for Synapse to become healthy
docker compose up -d cactus
```
 
Zur Kontrolle:
 
```bash
docker logs cactus --tail 50
docker logs synapse --tail 50
```

## Die Website bei Cactus registrieren
 
Bevor Cactus Kommentarräume für meinen Blog anlegen kann, muss ich meine Website beim `cactusbot` registrieren. Das geht direkt über [Element](https://app.element.io):
 
Einen neuen Chat mit `@cactusbot:matrix.your-domain.com` öffnen und eingeben:
 
```
register <websitename>
```
 
Wenn alles korrekt eingerichtet ist, antwortet der Bot mit einer Bestätigung. In den Container-Logs sieht der erfolgreiche Ablauf so aus:
 
```
INFO in app: Registration complete
INFO in app: Created site    name='websitename' owner='@your_name:matrix.your-domain.com'
INFO in app: Power level changed, replicating    room='#comments_websitename:matrix.your-domain.com'
```

## Hugo Integration
 
### Client-Dateien kopieren
 
```bash
cd ~/hugo/cactus-client
cp dist/cactus.js ~/hugo/blog/static/
cp dist/style.css ~/hugo/blog/static/cactus.css
```

### Shortcode erstellen
 
```bash
nvim ~/hugo/blog/layouts/shortcodes/chat.html
```
 
Mein Shortcode lädt den Cactus Client und initialisiert den Kommentarbereich. Ich habe ihn außerdem an mein **Catppuccin**-Farbschema angepasst – sowohl für den hellen Latte- als auch den dunklen Mocha-Modus:
 
```html
<script type="text/javascript" src="/cactus.js"></script>
<link rel="stylesheet" href="/cactus.css" type="text/css" />
<style>
  /* Fix avatar image distortion */
  .cactus-comment-avatar img {
    max-width: unset;
    width: 40px;
    height: 40px;
    object-fit: cover;
  }
  /* Catppuccin Latte (Light) */
  :root[data-theme="light"] {
    --cactus-text-color: #4c4f69;
    --cactus-text-color--soft: #6c6f85;
    --cactus-background-color: transparent;
    --cactus-background-color--strong: #e6e9ef;
    --cactus-border-color: #ccd0da;
    --cactus-border-width: 1px;
    --cactus-border-radius: 0.5em;
    --cactus-box-shadow-color: rgba(30, 102, 245, 0.15);
    --cactus-button-text-color: #4c4f69;
    --cactus-button-color: #dce0e8;
    --cactus-button-color--strong: #ccd0da;
    --cactus-button-color--stronger: #bcc0cc;
    --cactus-login-form-text-color: #4c4f69;
    --cactus-error-color: #d20f39;
  }
  /* Catppuccin Mocha (Dark) */
  :root[data-theme="dark"] {
    --cactus-text-color: #cdd6f4;
    --cactus-text-color--soft: #a6adc8;
    --cactus-background-color: transparent;
    --cactus-background-color--strong: #313244;
    --cactus-border-color: #45475a;
    --cactus-box-shadow-color: rgba(137, 180, 250, 0.18);
    --cactus-button-text-color: #cdd6f4;
    --cactus-button-color: #45475a;
    --cactus-button-color--strong: #585b70;
    --cactus-button-color--stronger: #6c7086;
    --cactus-login-form-text-color: #cdd6f4;
    --cactus-error-color: #f38ba8;
  }
</style>
<br />
<div id="comment-section"></div>
<script>
  initComments({
    node: document.getElementById("comment-section"),
    defaultHomeserverUrl: "https://matrix.your-domain.com",
    serverName: "matrix.your-domain.com",
    siteName: "websitename",
    commentSectionId: "{{ index .Params 0 }}",
  });
</script>
```
 
Alle verfügbaren Konfigurationsoptionen für `initComments` sind in der [Cactus Client Dokumentation](https://cactus.chat/docs/client/introduction/#configuration) beschrieben.

### Kommentarbereich in einen Beitrag einbinden
 
Ab sofort reicht eine einzige Zeile, um unter einem Artikel einen Kommentarbereich hinzuzufügen:
 
```
{{</* chat cactus-comments */>}}
```
 
Der Parameter `cactus-comments` ist der Name des Matrix-Raums für diesen Artikel. Jeder Raum bekommt automatisch den Alias `#comments_websitename_cactus-comments:matrix.your-domain.com`. Ich kann für jeden Artikel einen eigenen Raumnamen verwenden oder denselben für alle – das hängt davon ab, ob man Kommentare pro Artikel oder global zusammenführen möchte.

### Änderungen veröffentlichen
 
```bash
git add layouts/shortcodes/chat.html static/cactus.css static/cactus.js
git commit -m "migrate Cactus Comments to self-hosted matrix.your-domain.com"
git push origin
```
 
## Fazit
 
Was mich an Cactus Comments überzeugt: Es gibt keine externe Datenbank, kein Drittanbieter-Tracking, keine JavaScript-Payloads von fremden Domains.

Die Kommentare liegen als gewöhnliche Matrix-Events in meinem eigenen Synapse – gesichert mit meinem üblichen restic-Backup, versioniert, portierbar.
 
Gleichzeitig kann jeder, der einen Matrix-Account hat, sofort kommentieren – ganz egal, auf welchem Homeserver sein Account liegt. Und wer noch keinen Account hat, kann sich in wenigen Minuten einen auf `matrix.org` anlegen.
 
Das ist das Web, wie es sein sollte.

---
 
*Fragen oder Anmerkungen? Schreib mir direkt über Matrix: `@sebastian:matrix.techlab.icu` – oder hinterlasse einfach unten einen Kommentar. Der landet dann auch prompt in meiner Matrix.*

Liebe Grüße Sebastian

{{< chat self-hosting-matrix-homeserver-synapse >}}
