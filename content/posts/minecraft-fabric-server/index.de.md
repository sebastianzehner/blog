+++
title = 'Minecraft Fabric-Server: So richtest du einen modded Server zu Hause ein'
description = 'Schritt-für-Schritt-Anleitung für einen Minecraft Fabric-Server mit Mods auf Linux. Von der Installation über die Mod-Auswahl bis zum Betrieb im lokalen Netzwerk.'
summary = 'PaperMC reicht für Plugins — aber für echte Mods braucht es Fabric. Hier zeige ich dir, wie du einen modded Minecraft-Server auf Linux aufsetzt, mit über 20 Mods für Farming, Deko und Performance.'
date = 2026-07-29T12:00:00-03:00
lastmod = 2026-07-29T12:00:00-03:00

tags = ['minecraft', 'linux', 'bash', 'self-hosting', 'open-source', 'terminal']
categories = ['TechLab']

showComments = true
chatId = "minecraft-fabric-server"
+++

Du hast einen Minecraft-Server zu Hause laufen — alles funktioniert, Vanilla
pur, vielleicht ein paar Paper-Plugins. Aber jetzt willst du mehr: neue Biome,
Koch-Mods, Deko-Elemente, richtiges Modding. Das Problem: **PaperMC und
Fabric-Mods sind nicht kompatibel.** Paper versteht keine serverseitigen Mods
mit neuen Items, Blöcken oder Mechaniken.

Die Lösung ist ein paralleler **Fabric-Server** — komplett getrennt von deiner
Paper-Installation, mit eigenem Mod-Loader und einer eigenen Mod-Welt. In diesem
Artikel zeige ich dir, wie ich meinen Fabric-Server „Sumpfland" auf Linux
aufgesetzt habe, welche Mods ich installiert habe und worauf du beim Betrieb
achten musst.

## Warum ein zweiter Server?

In meinem Setup läuft bereits ein PaperMC-Server für Vanilla-Plugins.
Fabric-Mods brauchen den Fabric-Loader — und der ist inkompatibel mit Paper.
Also habe ich mich für einen zweiten, parallelen Server entschieden:

| Eigenschaft | PaperMC-Server               | Fabric-Server                         |
| ----------- | ---------------------------- | ------------------------------------- |
| Fokus       | Plugins (vanilla-kompatibel) | Mods (neue Blöcke, Items, Mechaniken) |
| Mod-Loader  | Keiner (Paper)               | Fabric Loader                         |
| Verzeichnis | `~/minecraft/server/`        | `~/minecraft/fabric-server/`          |

Beide Server laufen auf demselben Host — ein ThinkCentre M715q Gen. 2 — aber in
komplett getrennten Verzeichnissen. Kein Risiko, dass einer den anderen
beeinflusst.

> **Hinweis zu Mods vs. Add-ons:** Mods gibt es nur für die **Java Edition**.
> Die Bedrock Edition nutzt Add-ons, die deutlich eingeschränkter sind
> (JSON/Skript-basiert). Dieser Artikel bezieht sich ausschließlich auf die Java
> Edition mit Fabric.

## Voraussetzungen

Bevor du loslegst, brauchst du:

- **Java 21** (für Minecraft 1.21.x) oder **Java 25** (für Minecraft 26.x)
- Einen Linux-Host (bei mir ein ThinkCentre, aber jeder andere Server tut's auch)
- Mindestens **4 GB RAM** für den Server (bei über 20 Mods wie in diesem Setup
  eher 6–8 GB einplanen)
- `tmux` für Hintergrundbetrieb (optional, aber empfohlen)
- `curl` und `jq` (für Mod-Downloads und mein Update-Skript)

Java prüfen und bei Bedarf installieren:

```bash
java -version

# Falls nicht vorhanden:
sudo apt install openjdk-25-jre-headless
```

## Schritt 1: Verzeichnis anlegen

Erstelle einen eigenen Ordner für den Fabric-Server — komplett getrennt von
einem bestehenden Paper-Server:

```bash
cd ~/minecraft
mkdir fabric-server
cd fabric-server
```

## Schritt 2: Fabric-Server-JAR herunterladen

[Fabric](https://fabricmc.net/use/server/) bietet eine Meta-API, über die du die
Server-JAR direkt laden kannst — kein separater Installer nötig. Die URL folgt
diesem Muster:

```
https://meta.fabricmc.net/v2/versions/loader/{minecraft_version}/{loader_version}/{installer_version}/server/jar
```

Für Minecraft 26.2 mit Fabric Loader 0.19.3:

```bash
curl -OJ https://meta.fabricmc.net/v2/versions/loader/26.2/0.19.3/1.1.1/server/jar
```

Die heruntergeladene Datei heißt ähnlich wie `fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar`.

## Schritt 3: EULA akzeptieren

Bevor der Server startet, musst du die End User License Agreement akzeptieren:

```bash
echo "eula=true" > eula.txt
```

## Schritt 4: Fabric API installieren

Die [Fabric API](https://modrinth.com/mod/fabric-api) ist die Grundlage fast
aller Fabric-Mods. Ohne sie funktionieren die meisten Erweiterungen nicht.

```bash
mkdir -p mods
cd mods
curl -OJ "https://cdn.modrinth.com/data/P7dR8mSH/versions/Cpy2Px2f/fabric-api-0.154.0%2B26.2.jar?mr_download_reason=standalone&mr_game_version=26.2&mr_loader=fabric"
cd ..
```

> **Wichtig:** Die URL enthält `&`-Zeichen — immer in Anführungszeichen setzen,
> sonst bricht die Shell den Befehl ab. Falls der Dateiname URL-kodierte Zeichen
> enthält (`%2B` statt `+`), umbenennen:

```bash
mv "fabric-api-0.154.0%2B26.2.jar" "fabric-api-0.154.0+26.2.jar"
```

## Schritt 5: Start-Skript erstellen

Erstelle eine `start.sh`, um den Server komfortabel zu starten:

```bash
#! /bin/bash
java -Xmx4G -Xms2G -jar fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar nogui
```

Ausführbar machen:

```bash
chmod +x start.sh
```

Die RAM-Werte (`-Xmx`, `-Xms`) an deinen Host anpassen. Mit 4 GB max und 2 GB
startend lief es bei mir mit allen Mods und vier Spielern stabil — bei einer
umfangreicheren Modliste oder mehr Spielern gleichzeitig würde ich eher mit 6 GB
(-Xmx6G) planen.

## Schritt 6: Server mit tmux im Hintergrund starten

Für den Dauerbetrieb empfehle ich `tmux` — der Server läuft dann weiter, auch
wenn du das Terminal schließt:

```bash
tmux new -s fabric-server
cd ~/minecraft/fabric-server
./start.sh
```

Session verlassen (`Strg+B`, dann `D`), wieder anschauen mit `tmux attach -t
fabric-server`, alle Sessions auflisten mit `tmux ls`. Den Server sauber stoppen
mit dem Befehl `/stop` in der Konsole.

## Konfiguration: server.properties

Beim ersten Start erzeugt Fabric eine `server.properties` mit Standardwerten.
Die wichtigsten Anpassungen:

```properties
difficulty=normal
level-name=deine-welt
max-players=6
motd=§2Dein Server §8| §fMinecraft Fabric §a❤
server-port=25566
```

Wenn du parallel einen Paper-Server auf demselben Host betreibst, einen anderen
Port wählen (Standard ist 25565). Die MOTD unterstützt Farbcodes — `§2` ist
dunkelgrün, `§a` hellgrün, `§f` weiß, `§l` fett, `§o` kursiv.

### Operator-Rechte vergeben

Auf einem frischen Fabric-Server hat niemand Operator-Rechte. In der
Server-Konsole (tmux):

```bash
op dein-username
```

Für weitere Spieler wiederholen. Ohne OP-Rechte funktionieren Befehle wie
`/gamerule` oder `/kick` im Spielchat nicht — über die Server-Konsole (tmux)
funktionieren Admin-Befehle dagegen immer, unabhängig vom OP-Status.

### Server-Icon

Ein individuelles Server-Icon ist ein PNG in **exakt 64×64 Pixel**, abgelegt als
`server-icon.png` im Hauptverzeichnis (gleiche Ebene wie `eula.txt`). Nach dem
Kopieren einen Neustart durchführen.

## Mod-Auswahl: Was macht den Server aus?

Jetzt kommt der interessante Teil — die Mods. Meine Auswahl zielt auf
**familienfreundliches Gameplay**: Farming, Kochen, Deko, Weltgenerierung und
Performance. Keine aggressive PvP- oder Tech-Mods.

Hier sind die Highlights meiner Mod-Liste:

### Weltgenerierung: Terralith

[Terralith](https://modrinth.com/mod/terralith) verändert die Weltgenerierung
fundamental — über 95 neue Biome, Canyons, schwebende Inseln, Ozeangräben. Der
Clou: es nutzt **ausschließlich Vanilla-Blöcke**. Das Inventar bleibt
unverändert, nur die Landschaft wird vielfältiger.

> **Wichtig:** Terralith **muss vor der Generierung der Welt** installiert sein.
> Nachträglich hinzugefügt drohen Chunk-Grenzen-Fehler und Terrain-Brüche. Bei
> uns war es von Anfang an dabei.

Da Terralith keine neuen Blöcke oder Items registriert, muss es nur auf dem
**Server** installiert sein und der Client merkt technisch gar nicht, dass
Terralith läuft. Die zusätzliche Abhängigkeit **Lithostitched** (Library-Mod für
Weltgenerierung) ist ebenfalls nötig.

### Farming & Kochen: Farmer's Delight + Rustic Delight + Ube's Delight

[Farmer's Delight](https://modrinth.com/mod/farmers-delight-refabricated) ist
das Herzstück des Farming-Gameplays: neue Feldfrüchte, Küchengeräte, Gerichte
und ein eigenes Kochsystem. Darauf aufbauend:

- **[Rustic Delight](https://modrinth.com/mod/rustic-delight)** — Pancakes (6
  Geschmacksrichtungen), Kaffee, Paprika, Baumwolle, Calamari
- **[Ube's Delight](https://modrinth.com/mod/ubes-delight)** — philippinisch
  inspiriert: Ube (violette Süßkartoffel), Knoblauch, Ingwer, Ube Milk Tea, Halo
  Halo und einiges mehr

Alle drei Mods sind additiv — sie fügen dem Spiel neue Inhalte hinzu, ohne das
Grundspiel zu verändern. Vanilla-Items behalten ihre Funktion und bekommen
zusätzliche Rezeptmöglichkeiten.

### Deko: Beautify + Storage Delight + Too Many Paintings

Für optisch ansprechende Bauten:

- **[Beautify Refabricated](https://modrinth.com/mod/beautify-refabricated)** —
  Hängetöpfe, Jalousien, Bilderrahmen, neue Lichtquellen (Bambus-Laternen,
  Kronleuchter), Gitter und mehr
- **[Storage Delight](https://modrinth.com/mod/storage-delight)** — Schubladen,
  Bücherregale mit Türen, Glasschränke, Einzeltür-Schränke
- **[Too Many Paintings](https://modrinth.com/mod/too-many-paintings)** —
  deutlich mehr Gemälde mit durchsuchbaren GUI zur Auswahl

### Komfort: Comforts + Sit Anywhere + JourneyMap

- **[Comforts](https://modrinth.com/mod/comforts)** — Schlafsäcke und
  Hängematten zum Tag/Nacht überspringen
- **[Sit Anywhere!](https://modrinth.com/mod/sit-anywhere!)** — auf fast
  beliebigen Blöcken sitzen (Treppen, Zäune) per Rechtsklick
- **[JourneyMap](https://modrinth.com/plugin/journeymap)** — Minimap im Spiel
  plus Web-Map für den Browser (Port 8080)

### Performance: Lithium + Spark + Better Fabric Console

- **[Lithium](https://modrinth.com/mod/lithium)** — optimiert die interne
  Server-Spiellogik (Mob-KI, Redstone, Weltticking) für bessere Performance
- **[Spark](https://modrinth.com/mod/spark)** — Profiling-Tool zur Diagnose von
  Lag-Spikes und TPS-Einbrüchen
- **[Better Fabric Console](https://modrinth.com/mod/better-fabric-console)** —
  farbige Log-Ausgabe und Tab-Vervollständigung in der Server-Konsole

> **Achtung:** Better Fabric Console benötigt zusätzlich
> [adventure-platform-fabric](https://modrinth.com/mod/adventure-platform-mod)
> als Abhängigkeit. Ohne diese Datei startet der Mod ohne Farbausgabe.

### Technik: Carpet + The Möbius Automata

Für Redstone- und Technik-Interessierte:

- **[Carpet](https://modrinth.com/mod/carpet)** — zusätzliche Server-Regeln,
  Debug-Werkzeuge, Redstone-Analysehilfen
- **[The Möbius Automata](https://modrinth.com/mod/the-mbius-automata)** — ein
  auf Carpet aufbauender Bot-Mod, der Spieler automatisiert jagen, bauen und
  minen lässt

### Rezept-Übersicht: JEI

[JEI (Just Enough Items)](https://modrinth.com/mod/jei) zeigt alle Rezepte und
Item-Verwendungen direkt im Inventar an — besonders hilfreich mit Farmer's
Delight. Seit Minecraft 1.21.2 werden Rezepte serverseitig synchronisiert, daher
muss JEI auf **Server und Client** installiert sein.

### Server-Analytics: Plan

[Plan | Player Analytics](https://modrinth.com/plugin/plan) liefert ein
Web-Dashboard mit Spielzeiten, Login-Historie und Server-Performance-Trends.
Erreichbar im lokalen Netzwerk unter Port 8804.

## Mod-Installation auf dem Client

Im Gegensatz zu Ressourcenpacks werden Fabric-Mods **nicht automatisch** an
Clients verteilt. Jeder Mod, der neue Blöcke oder Items hinzufügt, muss
**manuell auf jedem Client** in exakt derselben Version installiert werden.

Über den **Prism Launcher** geht das einfach: Mod-Verwaltung → Mod suchen →
passende Version hinzufügen. Die Faustregel:

- **Neue Blöcke/Items** (z. B. Farmer's Delight) → Server **und** Client
- **Weltgenerierung oder Balance** (z. B. Terralith, Lithium) → nur Server
- **Server-Konsole / Analytics** (z. B. Better Fabric Console, Plan) → nur Server

Fehlt ein Mod oder stimmt die Version nicht überein, gibt der Client beim
Verbindungsversuch eine Fehlermeldung mit den fehlenden Mods aus.

## Mods automatisch updaten

Bei über 20 Mods wird das manuelle Nachschauen mühsam. Ich habe ein Bash-Skript
`check-updates.sh`, das alle `.jar`-Dateien im `mods`-Ordner per SHA1-Hash gegen
die **Modrinth API** prüft:

```bash
./check-updates.sh
```

Das Skript zeigt eine Übersicht (geprüft / aktuell / Update verfügbar) und fragt
bei gefundenen Updates nach, ob diese direkt installiert werden sollen. Alte
Dateien werden per `mv` gesichert, bei erfolgreichem Download wird das Backup
gelöscht.

```bash
#!/bin/bash
cd "$(dirname "$0")/mods" || { echo "❌ mods folder not found!"; exit 1; }

# Collect SHA1 hashes of all jars
hashes=$(sha1sum *.jar | awk '{print "\""$1"\""}' | paste -sd, -)

response=$(curl -s -X POST "https://api.modrinth.com/v2/version_files/update" \
  -H "Content-Type: application/json" \
  -d "{\"loaders\":[\"fabric\"],\"game_versions\":[\"26.2\"],\"algorithm\":\"sha1\",\"hashes\":[$hashes]}")

total=0
outdated=0
up_to_date=0
not_found=0
outdated_files=()
outdated_targets=()
outdated_urls=()

for jarfile in *.jar; do
  total=$((total + 1))
  hash=$(sha1sum "$jarfile" | cut -d' ' -f1)

  latest_hashes=$(echo "$response" | jq -r --arg h "$hash" '.[$h].files[]?.hashes.sha1 // empty')

  if [ -z "$latest_hashes" ]; then
    not_found=$((not_found + 1))
    continue
  fi

  if grep -qx "$hash" <<< "$latest_hashes"; then
    up_to_date=$((up_to_date + 1))
  else
    outdated=$((outdated + 1))
    latest_file=$(echo "$response" | jq -r --arg h "$hash" '.[$h].files[0].filename // empty')
    latest_url=$(echo "$response" | jq -r --arg h "$hash" '.[$h].files[0].url // empty')
    echo "🔄 Update available: $jarfile -> $latest_file"
    outdated_files+=("$jarfile")
    outdated_targets+=("$latest_file")
    outdated_urls+=("$latest_url")
  fi
done

echo ""
echo "----------------------------------------"
echo "📦 Total files checked: $total"
echo "✅ Up to date:          $up_to_date"
echo "🔄 Updates available:   $outdated"
echo "❓ Not found on Modrinth: $not_found"
echo "----------------------------------------"

if [ "$outdated" -eq 0 ]; then
  exit 0
fi

echo ""
read -p "Do you want to update these $outdated mod(s) now? [y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted, no changes made."
  exit 0
fi

echo ""
for i in "${!outdated_files[@]}"; do
  old="${outdated_files[$i]}"
  new="${outdated_targets[$i]}"
  url="${outdated_urls[$i]}"
  backup="${old}.bak"

  echo "➡  Updating $old -> $new"
  mv "$old" "$backup"

  if curl -sfL -o "$new" "$url"; then
    rm "$backup"
    echo "   ✅ Success, backup removed."
  else
    mv "$backup" "$old"
    echo "   ❌ Download failed, restored original file."
  fi
done

echo ""
echo "Done."
```

> **Wichtig:** Vor dem Ausführen den Server stoppen — keine `.jar`-Datei
> austauschen, während sie geladen ist. Das Skript benötigt `jq` (`apt install
jq`).

## Fazit

Ein Fabric-Server neben einem PaperMC-Server zu betreiben ist unproblematisch:
getrenntes Verzeichnis, Fabric Loader per Meta-API, Fabric API als Grundlage,
und dann nach Lust und Laune Mods nachlegen. Der Aufwand für die initiale
Einrichtung liegt bei unter 30 Minuten — alles danach ist Mod-Auswahl und
Konfiguration.

Für mich war der größte Gewinn die Kombination aus Terralith (visuell
abwechslungsreiche Welt) und den Delight-Mods (entspanntes Farming und Kochen).
Das ergibt einen Server, auf dem die ganze Familie mitmachen kann — ohne
aggressive Gameplay-Veränderungen. Den PaperMC werde ich nur noch als Backup
aufbewaren und irgendwann löschen.

Wenn du Fragen hast oder selbst einen Fabric-Server betreibst: lass es mich
wissen. Ich freue mich über Kommentare und Tipps für die Mod-Konfiguration.

Liebe Grüße  
Sebastian
