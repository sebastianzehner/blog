+++
title = 'Docker Compose im Homelab: Mein Weg zu einer vernetzten Container-Infrastruktur'
summary = 'Mit klar strukturierten Volumes, eigenen Netzwerken und etwas Automatisierung laufen meine Dienste zuverlässig über mehrere Linux-Systeme. Sie sind schnell einsatzbereit, leicht aktualisierbar und stabil.'
date = 2025-08-15T09:04:00-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-15T09:04:00-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Docker', 'Compose', 'Container', 'Homelab', 'IPvlan', 'Networking']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/docker-compose-homelab-my-journey-connected-container-infrastructure.webp'
    alt = 'Beitragsbild von Docker Compose im Homelab: Mein Weg zu einer vernetzten Container-Infrastruktur'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Ob man ein kleines Heimnetzwerk betreibt oder ein ausgewachsenes Homelab - Docker bietet mit Docker Compose eine flexible und saubere Möglichkeit, Dienste zu betreiben, zu vernetzen und zu verwalten.

Als ich vor einigen Jahren meinen ersten **Docker-Container** gestartet habe, hätte ich nicht gedacht, dass sich daraus ein zentrales Fundament meines **Homelabs** entwickeln würde. Anfangs war Docker für mich nur ein praktisches Tool, um schnell einen einzelnen Dienst bereitzustellen.

Heute laufen bei mir dutzende Services. Sie sind verteilt auf vier Linux-Systeme, organisiert und gesteuert mit **Docker Compose** und verbunden in einem eigenen **Docker-Netzwerk**.

Docker ist inzwischen so tief in meinen Alltag integriert, dass ich viele meiner Dienste nicht mehr anders betreiben möchte. Es macht Deployments reproduzierbar, Updates kontrollierbar und das Management deutlich einfacher - egal ob auf einem Mini-PC, einem Server im Rack oder einer kleinen virtuellen Maschine.

## Docker installieren auf unterschiedlichen Linux-Systemen

Einer der Gründe, warum ich Docker so gerne nutze, ist die Flexibilität bei der Installation. In meinem Homelab setze ich verschiedene Linux-Distributionen ein - und Docker läuft überall:

- **Alpine Linux:** Ideal für minimalistische Setups, Installation über `apk` in wenigen Sekunden.
- **Arch Linux:** Dank `pacman` und dem offiziellen docker-Paket ist die Installation schnell erledigt.
- **Debian / Ubuntu:** Über das Docker-Repository bekomme ich aktuelle Versionen direkt per `apt`.

Zusätzlich installiere ich **Docker Compose**, damit ich alle Systeme mit der gleichen Syntax steuern kann.

> **Hinweis:** In meinen Beispielen nutze ich unter Alpine Linux den Befehl `doas` (ähnlich wie `sudo`), da Alpine standardmäßig `sudo` nicht mitbringt. Auf allen anderen Systemen verwende ich `sudo`.

### Alpine Linux

```bash
doas apk add docker docker-compose
```

Den Docker-Dienst automatisch beim Boot starten lassen und den Benutzer zur Gruppe `docker` hinzufügen:

```bash
doas rc-update add docker default
doas /etc/init.d/docker start
doas addgroup $USER docker
```

### Arch Linux

```bash
sudo pacman -S docker docker-compose
```

### Debian / Ubuntu

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Unter Arch Linux und Ubuntu startet der Docker-Dienst automatisch aber mit folgendem Befehl kann er manuell gestartet werden:

```bash
sudo systemctl start docker
```

Und auch hier sollte der Benutzer der Gruppe `docker` hinzugefügt werden:

```bash
sudo usermod -aG docker $USER
```

Nach der Installation können einmal folgende Befehle ausprobiert werden, um zu sehen, ob alles geklappt hat:

```bash
docker info
docker ps
```

## Datenorganisation und Volumes

**Einer meiner Grundsätze im Homelab:** Trenne Konfiguration und Daten vom Container.
Ich strukturiere meine Volumes klar nach Diensten, z. B.:

```bash
# Konfiguration
~/docker-compose/
   ├── traefik/
   ├── komodo/
   ├── jellyfin/
   ├── frigate/

# Daten und Volumes
~/docker/
   ├── traefik/
   ├── komodo/
   ├── jellyfin/
   ├── frigate/
```

So kann ich nicht nur schnell Backups erstellen, sondern auch Dienste verschieben oder neu aufsetzen, ohne dass Daten verloren gehen.

Zum Thema Backup werde ich noch einen separaten Artikel schreiben, in dem **Restic** die Hauptrolle spielen wird.

## Docker Networking - das unsichtbare Rückgrat

Einer der größten Gamechanger für mich war Docker Networking.

Anstatt dass jeder Dienst irgendwo zufällig im Netzwerk hängt, habe ich ein eigenes internes Netzwerk für meine Container erstellt. Dienste können so direkt miteinander sprechen, ohne dass Ports unnötig nach außen offen sind.

In Kombination mit **Traefik** (mehr dazu im nächsten Artikel) kann ich jeden Dienst bequem über eine Subdomain erreichen - egal ob `komodo.meinedomain.com` oder `jellyfin.meinedomain.com`.

Für mich bedeutet das: Keine wilden Portnummern mehr merken und ein sauberes, zentrales Routing.

### Macvlan oder IPvlan für Docker einrichten

Ich habe mich letztendlich für **IPvlan** entschieden und mir damit mein Docker-Netzwerk aufgebaut. Mehr Details darüber wird es sicherlich im Traefik Blogpost geben, aber hier einmal die Befehle zum Erstellen des Proxy Netzwerks:

```bash
sudo docker network create -d ipvlan --subnet 192.168.x.x/24 --gateway 192.168.x.x -o parent=enp1s0f0 proxy
```

Den Namen von der Netzwerkkarte des Servers herausfinden mit:

```bash
ip address show
```

Die Netzwerkkarte des `sumpfgeist.lan` Servers heißt `enp1s0f0` und diesen Namen nutzte ich zur Konfiguration für das Docker IPvlan.

**Eine wichtige Information bei der Verwendung dieser Konfiguration:**

Ich vergebe meine IP-Adressen für die Docker Container alle manuell in den `docker-compose.yaml` Dateien, damit es nicht zu IP-Adressen Konflikten kommt, weil Docker würde ansonsten einfach die IP-Adressen vergeben ohne Rücksicht auf meinen DHCP-Server.

Hier mal ein Beispiel von einer einfachen Meshtastic Webanwendung mit manuell vergebener IP Adresse und Labels für den Traefik Reverse-Proxy mit Nutzung des externen `proxy` IPvlan Netzwerk:

```bash
services:
  meshtastic-web:
    image: ghcr.io/meshtastic/web
    container_name: meshtastic
    restart: unless-stopped
    networks:
      proxy:
        ipv4_address: 192.168.x.x
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.meshtastic.entrypoints=http"
      - "traefik.http.routers.meshtastic.rule=Host(`meshtastic.techlab.icu`)"
      - "traefik.http.middlewares.meshtastic-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.meshtastic.middlewares=meshtastic-https-redirect"
      - "traefik.http.routers.meshtastic-secure.entrypoints=https"
      - "traefik.http.routers.meshtastic-secure.rule=Host(`meshtastic.techlab.icu`)"
      - "traefik.http.routers.meshtastic-secure.tls=true"
      - "traefik.http.routers.meshtastic-secure.service=meshtastic"
      - "traefik.http.services.meshtastic.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"
networks:
  proxy:
    external: true
```

Das Docker-Netzwerk habe ich auch auf anderen Servern eingerichtet, wie beispielsweise auf dem `eq14.lan` mit **Alpine Linux**:

```bash
doas docker network create -d ipvlan --subnet 192.168.x.x/24 --gateway 192.168.x.x -o parent=eth0 proxy
```

### Warum ich IPvlan statt Macvlan nutze

Einer der entscheidenden Gründe war die Netzwerk **Kompatibilität**:

- **Nur eine MAC-Adresse pro physischer Schnittstelle** - bei Macvlan bekommt jeder Container eine eigene MAC-Adresse. Das kann bei manchen Switches, Routern oder insbesondere bei Consumer-Geräten zu Problemen führen, weil sie mehrere MACs an einem Port nicht sauber unterstützen.
- **Einfachere Layer-2-Handhabung** - IPvlan arbeitet aus Sicht des Netzwerks wie eine einzige Schnittstelle und verteilt die IP-Adressen intern weiter. Dadurch sinkt die Gefahr von Broadcast- oder ARP-Problemen.
- **Bessere Performance in manchen Szenarien** - IPvlan umgeht die virtuelle Netzwerktreiber-Schicht, die Macvlan oft bremst, und kann deshalb gerade bei vielen Containern effizienter arbeiten.
- **Kompatibler mit Firewalls und VLANs** - manche Sicherheits- oder Management-Systeme verhalten sich zuverlässiger, wenn nur eine MAC-Adresse pro Port genutzt wird.

## Management: CLI statt Klick-Interface

Obwohl es Tools wie Komodo gibt, mit denen ich meine vier Docker-Hosts zentral im Blick habe, passiert meine eigentliche Arbeit fast ausschließlich im Terminal.

Ich bevorzuge die direkte Kontrolle beispielsweise mit:

```bash
docker ps
docker compose up -d
docker compose down
```

Jeder Dienst hat seine eigene `docker-compose.yaml` Konfigurationsdatei und das hält Konfigurationen nachvollziehbar und übersichtlich.

Außerdem liebe ich mein Terminal und bevorzuge daher bewusst die CLI-Befehle (`docker` & `docker compose`) für Skripte, Automatisierung, Backups, SSH-Zugriff usw.

### Warum ich Komodo statt Portainer nutze

Viele setzen im Homelab auf Portainer, um Container über eine Weboberfläche zu verwalten. Für meinen Workflow reicht mir jedoch Komodo völlig aus - ein leichtgewichtiges, Open-Source-Dashboard, das mir den Status aller eingebundenen Systeme auf einen Blick zeigt.

Die eigentliche Verwaltung erledige ich ohnehin über das Terminal, sodass Komodo für mich genau die richtige Balance aus Übersicht und Minimalismus bietet.

## Vorteile von Docker Compose im Homelab

- **Schnell einsetzbar:** Neuer Service? `docker compose up` und er läuft.
- **Weniger Chaos:** Keine Paketkonflikte oder Abhängigkeiten auf dem Host.
- **Portabilität:** Container können leicht auf andere Systeme umziehen.
- **Konsistenz:** Egal ob auf Arch, Debian oder Alpine - die Dienste verhalten sich identisch.

## Ausblick

In einem kommenden Artikel werde ich tiefer auf **Traefik** eingehen. Das ist mein zentraler Reverse Proxy, der mein Docker-Netzwerk mit der Außenwelt verbindet.

Die Außenwelt bekommt unter anderem den Zugang über einen **Cloudflare Tunnel** oder **Twingate**, beides ebenfalls als Docker Container im Netzwerk und sicherlich auch ein eigenes Thema hier auf meinem Blog wert.

Außerdem plane ich einen Beitrag über Backups mit **Restic**, damit auch im Homelab kein Datenverlust droht. Das Backup läuft bei mir automatisiert über ein Skript per Cronjob.

## Container-Strategie: So verteile ich meine Docker-Services im Homelab

Zum Abschluss vielleicht eine kleine Liste, was bei mir aktuell als Docker Container im Homelab läuft:

- Traefik (2x)
- Frigate
- Meshtastic
- Komodo Core
- Komodo Periphery (4x)
- Searxng
- Twingate
- Mixpost
- Cloudflare Tunnel
- Gluetun
- Linkwarden
- PeaNUT
- Baikal
- IT-Tools
- Home Assistant
- Synapse
- Gotify
- Stirling PDF
- Glance
- Uptime Kuma
- Wordpress
- n8n
- Wiki.js
- Jellyfin

Alle hier aufgelisteten Container laufen rund um die Uhr, verteilt auf mehrere Systeme wie zum Beispiel:

- **Synology NAS:** Jellyfin (Mediaserver) - optimal, weil die Medien ohnehin dort liegen.
- **EQ14 Mini-PC mit zwei LAN-Schnittstellen:** Frigate (NVR), separater Traefik Reverse-Proxy - hier sind die dedizierten Netzwerkports und die zusätzliche Rechenleistung ideal für KI-gestützte Videoverarbeitung.
- **Lenovo ThinkCentre M715q:** Alle anderen produktiven Dienste wie Mixpost, Wiki.js, Searxng, Home Assistant, etc.
- **Vierter Host:** Wird nur bei Bedarf für zeitlich begrenzte Container-Tests oder Spezialprojekte gestartet.

Anfangs lief Frigate auch auf dem ThinkCentre, was zwar funktional war, jedoch mehr Ressourcen beanspruchte. Durch die Auslagerung auf den EQ14 bleibt der Hauptserver nun deutlich entlastet. Zu meinem Frigate Blogpost geht's [hier](/de/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

Einen Docker Swarm habe ich bewusst nicht eingesetzt - bei meiner überschaubaren Anzahl an Hosts ist die Kombination aus gezielter Container-Verteilung und einem zweiten Traefik-Proxy auf dem EQ14 eine einfachere und robustere Lösung aber wer weiß was die Zukunft noch bringt?

## Fazit

Docker Compose ist für mich längst mehr als nur ein Tool - es ist das Fundament meines Homelabs. Mit klarer Organisation, sauberem Networking und ein bisschen Automatisierung lässt sich damit eine robuste, flexible und leicht wartbare Umgebung aufbauen, die den Alltag enorm erleichtert.

Nutzt ihr **Docker** oder **Docker Compose** im Homelab? Schreibt mir gern in die Kommentare, wie ihr eure Container organisiert!

## Hardware-Empfehlungen

- EQ14 Mini-PC [auf Amazon](https://amzn.to/4oBKKcg) - kompakter und stromsparender Rechner für Docker
- Lenovo ThinkCentre M715q [bei RAM-KÖNIG](https://www.ram-koenig.de/lenovo-thinkcentre-m715q-ryzen5pro2400ge-8gbddr4) - gebrauchter Tiny PC als Server für Docker

_Da es sich teilweise um Affiliate-Links handelt, hier der Hinweis: Als Amazon-Partner verdiene ich an qualifizierten Verkäufen._

**Verwendete Tools:**

- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/traefik)
- [Komodo](https://komo.do/)

{{< chat Docker >}}
