---
title: "Eigener Matrix-Homeserver mit Synapse – Warum du deine Chats selbst hosten solltest"
summary: In diesem Artikel richte ich meinen eigenen Matrix-Homeserver mit Synapse und Docker Compose ein. Neben einer kurzen Einführung in das dezentrale Matrix-Protokoll zeige ich die vollständige Installation mit PostgreSQL, Traefik, Cloudflare Tunnel und Federation.
date: 2026-04-08T11:00:00-03:00
lastmod: 2026-04-08T11:00:00-03:00
draft: false
tags:
  - matrix
  - homeserver
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
  image: /img/matrix-homeserver-cover.webp
  alt: Matrix Homeserver
  hidden: false
  relative: false
  responsiveImages: false
---

_Dezentralisierung, Datenschutz und volle Kontrolle über deine Kommunikation – mit Synapse und Docker ist das einfacher als gedacht._

## Was ist Matrix – und warum ist es anders?

Die meisten Messenger, die wir täglich nutzen – WhatsApp, Telegram, Signal, iMessage – haben eines gemeinsam: Sie sind zentral organisiert. Das bedeutet, deine Nachrichten laufen über Server, die du nicht kontrollierst. Du vertraust einem Unternehmen, das die Infrastruktur betreibt, deine Daten schützt und den Dienst am Laufen hält. Was passiert, wenn das Unternehmen verkauft wird, die Datenschutzrichtlinien ändert oder einfach den Dienst einstellt?

[Matrix](https://matrix.org) löst dieses Problem mit einem anderen Ansatz: Es ist ein **offenes, dezentrales Kommunikationsprotokoll**. Ähnlich wie früher bei E-Mail kann jeder seinen eigenen Server betreiben, und alle Server können miteinander kommunizieren – das nennt sich **Federation**. Dein Account auf `@du:dein-server.de` kann problemlos mit jemandem auf `@andere:matrix.org` schreiben, genauso wie du von Gmail an eine Outlook-Adresse mailen kannst.

Das bedeutet:

- **Keine Abhängigkeit** von einem einzigen Anbieter
- **Vollständige Ende-zu-Ende-Verschlüsselung** (optional, aber empfohlen)
- **Selbstbestimmung**: Du entscheidest, wer auf deinem Server einen Account anlegen kann
- **Brücken (Bridges)**: Matrix lässt sich mit WhatsApp, Telegram, Discord, Signal und vielen anderen Diensten verbinden – alles in einem Client

Der bekannteste Matrix-Homeserver ist Synapse, entwickelt von Element (früher New Vector). Er ist in Python geschrieben, gut dokumentiert und lässt sich mit Docker hervorragend selbst hosten.

## Warum selbst hosten?

Wer einen eigenen Synapse-Server betreibt, gewinnt mehreres auf einmal:

**Datenschutz**: Deine Nachrichten und Medien liegen auf deiner eigenen Infrastruktur. Durch Federation können Raumevents jedoch auch auf den Servern anderer Teilnehmer repliziert werden – du behältst aber die Kontrolle über deine eigenen Daten und bist nicht das Produkt eines kommerziellen Anbieters.

**Kontrolle über Backups**: Keine App-spezifischen Backup-Lösungen mehr. Du sicherst die PostgreSQL-Datenbank und das Medieverzeichnis nach deinen eigenen Regeln – zum Beispiel mit [restic](https://restic.net/).

**Eigene Nutzeraccounts**: Du kannst für Familie, Freunde oder eine Community Accounts anlegen. Der Server gehört dir.

**Bridges als zentraler Hub**: Statt fünf verschiedene Apps zu öffnen, kannst du WhatsApp, Telegram oder Discord über Matrix-Bridges in deinen bevorzugten Matrix-Client einbinden. Ein Client für alles.

**Langlebigkeit**: Solange dein Server läuft, existieren deine Chaträume und deren History. Kein Anbieter kann sie dir wegnehmen.

## Voraussetzungen

Für diese Anleitung benötigst du:

- Einen Linux-Server (ich nutze Alpine Linux) mit Docker und Docker Compose
- Einen Reverse Proxy – ich verwende **Traefik**
- Eine Domain – ich nutze `matrix.techlab.icu`
- Optional: Einen Cloudflare-Tunnel für externen Zugang

## Installation mit Docker Compose

### Verzeichnisstruktur anlegen

Zuerst legen wir die nötigen Verzeichnisse an:

```bash
mkdir ~/docker-compose/synapse
mkdir ~/docker/synapse
mkdir ~/docker/synapse/files
mkdir ~/docker/synapse/db-data

touch ~/docker-compose/synapse/docker-compose.yml
```

> Das entspricht meiner persönlichen Verzeichnisstruktur für alle Docker-Container: Volume-Daten liegen unter `~/docker`, die `docker-compose.yml` und `.env` unter `~/docker-compose`. So bleibt alles übersichtlich und ich sichere genau diese beiden Verzeichnisse regelmäßig mit restic. Vielleicht schreibe ich dazu noch einen eigenen Artikel.

### docker-compose.yml

Hier meine produktive Konfiguration mit Synapse, PostgreSQL und Traefik-Integration:

```yaml
services:
  synapse:
    container_name: synapse
    image: docker.io/matrixdotorg/synapse:latest
    restart: unless-stopped
    environment:
      - SYNAPSE_CONFIG_PATH=/data/homeserver.yaml
      - UID=1000
      - GID=1000
    volumes:
      - /home/user/docker/synapse/files:/data
    depends_on:
      - synapse-db
    networks:
      synapse:
      proxy:
        ipv4_address: 192.168.10.70

    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"

      # HTTP to HTTPS Redirect
      - "traefik.http.routers.synapse.entrypoints=http"
      - "traefik.http.routers.synapse.rule=Host(`matrix.techlab.icu`)"
      - "traefik.http.middlewares.synapse-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.synapse.middlewares=synapse-https-redirect"

      # Main Secure Router for Synapse
      - "traefik.http.routers.synapse-secure.entrypoints=https"
      - "traefik.http.routers.synapse-secure.rule=Host(`matrix.techlab.icu`)"
      - "traefik.http.routers.synapse-secure.tls=true"
      - "traefik.http.routers.synapse-secure.service=synapse"
      - "traefik.http.services.synapse.loadbalancer.server.port=8008"

      # Define middleware to block the static path
      - "traefik.http.middlewares.block-synapse-static.replacepath.path=/forbidden"
      - "traefik.http.routers.synapse-static.rule=Host(`matrix.techlab.icu`) && PathPrefix(`/_matrix/static`)"
      - "traefik.http.routers.synapse-static.entrypoints=https"
      - "traefik.http.routers.synapse-static.tls=true"
      - "traefik.http.routers.synapse-static.middlewares=block-synapse-static"
      - "traefik.http.routers.synapse-static.priority=100"

  synapse-db:
    image: docker.io/postgres:15-alpine
    container_name: synapse-db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=synapse_user
      - POSTGRES_PASSWORD=secure_password
      - POSTGRES_DB=synapse
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - /home/user/docker/synapse/db-data:/var/lib/postgresql/data
    networks:
      synapse:

networks:
  synapse:
  proxy:
    external: true
```

Ein paar Anmerkungen zur Konfiguration:

- Synapse bekommt eine **feste IP** im `proxy`-Netzwerk, damit Traefik ihn zuverlässig anspricht.
- Die `block-synapse-static`-Middleware verhindert, dass `/_matrix/static` öffentlich erreichbar ist – dort liegt nur die Standard-Willkommensseite, die niemand von außen braucht. Der Pfad wird intern auf umgeschrieben, was einen 404-Fehler erzeugt.
- PostgreSQL wird mit `lc-collate=C` und `lc-ctype=C` initialisiert – das ist eine offizielle Anforderung von Synapse für korrekte Datenbankoperationen.

### Konfigurationsdatei generieren

Synapse bringt einen Generator für die initiale `homeserver.yaml` mit. Wir starten den Container einmalig im Generierungsmodus:

```bash
docker run -it --rm \
  --mount type=volume,src=synapse-data,dst=/data \
  -e SYNAPSE_SERVER_NAME=matrix.techlab.icu \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

Der Container legt die generierten Dateien in einem Docker-Volume ab. Als Root kopieren wir sie in unser Arbeitsverzeichnis:

```bash
sudo -i
cd /var/lib/docker/volumes/synapse-data/_data/
cp * /home/user/docker/synapse/files
exit

cd /home/user/docker/synapse/files
sudo chown user: *
```

### homeserver.yaml anpassen

Jetzt öffnen wir die `homeserver.yaml` und konfigurieren die Datenbankanbindung. Die SQLite-Standardkonfiguration ersetzen wir durch den PostgreSQL-Block:

```yaml
database:
  name: psycopg2
  args:
    user: synapse_user
    password: secure_password
    database: synapse
    host: synapse-db
    cp_min: 5
    cp_max: 10
```

Der Hostname `synapse-db` entspricht dem Container-Namen aus der `docker-compose.yml` – Docker löst ihn intern auf.

### Server starten

```bash
cd ~/docker-compose/synapse
docker compose up -d
```

Nach dem Start sollte unter `https://matrix.techlab.icu` folgende Meldung erscheinen:

```
It works! Synapse is running
Your Synapse server is listening on this port and is ready for messages.

To use this server you'll need a Matrix client.

Welcome to the Matrix universe :)
```

## Externen Zugang mit Cloudflare Tunnel

Damit der Server auch von außerhalb des Heimnetzwerks erreichbar ist, richte ich einen **Cloudflare Tunnel** ein. Dort wird ein Public Hostname angelegt:

- **Hostname**: `matrix`
- **Domain**: `techlab.icu`
- **Service Type**: `https`
- **URL**: `matrix.techlab.icu`

Wichtig: Service Type `https` stellt sicher, dass die Verbindung vom Cloudflare-Edge bis zu Traefik vollständig verschlüsselt bleibt. Intern löst der Pi-hole DNS `matrix.techlab.icu` auf die IP des Traefik-Servers auf.

## Federation aktivieren

Matrix lebt davon, dass verschiedene Server problemlos miteinander kommunizieren können. Damit mein Server mit `matrix.org` und anderen Servern kommunizieren kann, muss die Federation aktiviert sein. Standardmäßig nutzt Synapse dafür Port 8448 – ich leite es stattdessen über Port 443, was durch den Cloudflare Tunnel ohnehin genutzt wird.

In der `homeserver.yaml`:

```yaml
# allow room access over federation
matrix_synapse_allow_public_rooms_over_federation: true

# enable federation on port 443
serve_server_wellknown: true
```

Den Status lässt sich mit dem [Matrix Federation Tester](https://federationtester.matrix.org/) prüfen. Ein erfolgreicher Report sieht so aus:

```
Got 4 connection reports.
Homeserver version: Synapse 1.150.0

[IPv4-Adresse]:443  ✓ Success
[IPv4-Adresse]:443  ✓ Success
[IPv6-Adresse]:443  ✓ Success
[IPv6-Adresse]:443  ✓ Success
```

**Hinweis aus der Praxis**: Selbst nachdem der Federation Tester alles grün zeigt, kann es noch eine Weile dauern, bis die Kommunikation mit externen Servern zuverlässig funktioniert. Etwas Geduld ist hier gefragt – nach einigen Minuten klappt es dann aber problemlos.

## Administrator-Account anlegen

Den ersten Nutzer – gleichzeitig Administrator – erstellen wir direkt im laufenden Container:

```bash
docker exec -it synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml
```

Der Befehl fragt interaktiv nach Benutzername, Passwort und ob der Account Admin-Rechte haben soll.

## Matrix Clients

### Element Web & Desktop

Der bekannteste Matrix-Client ist **Element**. Er ist als Web-App unter [app.element.io](https://app.element.io) verfügbar sowie als Desktop-App für macOS, Windows und Linux.

Beim ersten Login auf dem eigenen Server muss die Server-URL manuell auf `https://matrix.techlab.icu` gesetzt werden. Auf macOS kann es vorkommen, dass der Client erst nach einer Sicherheitsabfrage des Betriebssystems vollständig funktioniert – macOS fragt, ob die App auf das lokale Netzwerk zugreifen darf. Diese Freigabe erteilen und den Client neu starten.

### Geräte verifizieren

Matrix unterstützt Cross-Signing zur Geräteverifizierung. Meldet man sich auf einem zweiten Gerät an, erscheint auf beiden Geräten ein Fenster mit identischen Symbolen und Begriffen. Stimmen die Symbole überein und bestätigt man das auf beiden Seiten, sind die Geräte sicher verifiziert. Ab diesem Moment sind Nachrichten zwischen den verifizierten Geräten Ende-zu-Ende-verschlüsselt.

### Schlüsselsicherung einrichten

Beim ersten Login wird angeboten, eine **Schlüsselsicherung** einzurichten. Das sollte man nicht überspringen. Dabei wird ein Wiederherstellungsschlüssel generiert, den man sicher aufbewahren muss – ich speichere ihn in [KeePassXC](https://keepassxc.org), sowohl als geschützten Eintrag als auch als Datei-Export.

Ohne diesen Schlüssel sind verschlüsselte Nachrichten nach einem Geräteverlust oder einem Neustart ohne aktive Session unwiederbringlich verloren.

### iamb – Matrix im Terminal

Für alle, die ihr Terminal nicht verlassen wollen: [iamb](https://iamb.chat) ist ein vollwertiger Matrix-Client im Terminal-Stil, inspiriert von Vim-Keybindings. Wer mit `nvim` und `tmux` arbeitet, wird sich sofort heimisch fühlen.

## Backup-Strategie

Synapse braucht zwei Dinge gesichert:

**1. Die PostgreSQL-Datenbank** (`~/docker/synapse/db-data/`): Hier liegen alle Matrix-Events – Nachrichten, Raumhistorie, Metadaten.

**2. Die Dateien** (`~/docker/synapse/files/`): Konfiguration, hochgeladene Medien (media_store) und – besonders wichtig – der **Signing Key**.

Der Signing Key ist der kryptografische Identitätsnachweis des Servers im Matrix-Netzwerk. Geht er verloren, vertrauen andere Server dem eigenen nicht mehr, die Federation bricht zusammen und man müsste den Server neu aufsetzen. Deshalb habe ich ihn zusätzlich zum restic-Backup noch in meinem Passwortmanager hinterlegt.

Ich sichere das gesamte `~/docker/`-Verzeichnis automatisiert mit restic – damit sind beide kritischen Pfade immer dabei.

## Ausblick: Bridges und Cactus Comments

Das ist erst der Anfang. Matrix ist durch sein offenes Protokoll eine hervorragende Grundlage für weitere Integrationen:

**Bridges** erlauben es, andere Messenger-Dienste anzubinden. Wer seinen WhatsApp-, Telegram- oder Discord-Verkehr über den eigenen Matrix-Server laufen lassen möchte, kann das mit entsprechenden Bridge-Containern realisieren. Alles landet dann in einem einzigen Matrix-Client.

Ich nutze aktuell keine Bridges aber ich überlege mir da etwas mit E-Mail einzurichten, weil wir bei E-Mail leider nicht mehr frei sind und keinen eigenen E-Mail Server ohne weiteres im Homelab selbst hosten können.

**Cactus Comments** nutzt Matrix als Backend für Blogkommentare. Für jeden Blogartikel existiert ein eigener Matrix-Chatraum, in dem Leser Kommentare hinterlassen können – ohne Account bei einem externen Kommentarsystem. Dazu mehr in einem separaten Artikel. Cactus Comments läuft bereits hier auf meinem Blog über meinen eigenen Synapse Server.

_Hast du Fragen zu deiner eigenen Synapse-Installation? Schreib mir gerne – am besten direkt über Matrix. Meine Adresse: `@sebastian:matrix.techlab.icu` oder schreibe einen Kommentar. Dieser landet am Ende auch in meiner Matrix._

Liebe Grüße Sebastian

{{< chat self-hosting-matrix-homeserver-synapse >}}
