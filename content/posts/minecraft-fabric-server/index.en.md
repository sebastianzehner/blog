+++
title = 'Setting Up a Minecraft Fabric Server at Home: A Step-by-Step Guide'
description = 'A step-by-step guide for setting up a modded Minecraft Fabric server on Linux. From installation through mod selection to running it on your local network.'
summary = 'PaperMC is great for plugins — but for real mods you need Fabric. Here is how to set up a modded Minecraft server on Linux with over 20 mods for farming, decoration, and performance.'
date = 2026-07-29T12:00:00-03:00
lastmod = 2026-07-29T12:00:00-03:00

tags = ['minecraft', 'linux', 'bash', 'self-hosting', 'open-source', 'terminal']
categories = ['TechLab']

[params]
showComments = true
chatId = "minecraft-fabric-server"

[translation]
  tool = 'Pi Agent - Qwen3.6-27B'
  version = '0.83.0'
  from = 'de'
  to = 'en'
  date = 2026-07-30T10:36:42-03:00
+++

You have a Minecraft server running at home — everything works, pure Vanilla,
maybe a few Paper plugins. But now you want more: new biomes, cooking mods,
decorative elements, real modding. The problem: **PaperMC and Fabric mods are
not compatible.** Paper does not understand server-side mods with new items,
blocks, or mechanics.

The solution is a parallel **Fabric server** — completely separate from your
Paper installation, with its own mod loader and its own modded world. In this
article I will show you how I set up my Fabric server "Sumpfland" on Linux,
which mods I installed, and what you need to pay attention to during operation.

## Why a Second Server?

In my setup, a PaperMC server is already running for Vanilla plugins. Fabric
mods require the Fabric loader — which is incompatible with Paper. So I went
with a second, parallel server:

| Feature    | PaperMC Server               | Fabric Server                       |
| ---------- | ---------------------------- | ----------------------------------- |
| Focus      | Plugins (vanilla-compatible) | Mods (new blocks, items, mechanics) |
| Mod Loader | None (Paper)                 | Fabric Loader                       |
| Directory  | `~/minecraft/server/`        | `~/minecraft/fabric-server/`        |

Both servers run on the same host — a ThinkCentre M715q Gen. 2 — but in
completely separate directories. No risk of one affecting the other.

> **Mods vs. Add-ons:** Mods are available only for the **Java Edition**. The
> Bedrock Edition uses add-ons, which are significantly more limited
> (JSON/script-based). This article focuses exclusively on the Java Edition with
> Fabric.

## Prerequisites

Before you get started, you need:

- **Java 21** (for Minecraft 1.21.x) or **Java 25** (for Minecraft 26.x)
- A Linux host (mine is a ThinkCentre, but any server works)
- At least **4 GB RAM** for the server (for a mod list like this one with over
  20 mods, plan for 6–8 GB)
- `tmux` for background operation (optional, but recommended)
- `curl` and `jq` (for mod downloads and my update script)

Check and install Java if needed:

```bash
java -version

# If not installed:
sudo apt install openjdk-25-jre-headless
```

## Step 1: Create the Directory

Create a dedicated folder for the Fabric server — completely separate from any
existing Paper server:

```bash
cd ~/minecraft
mkdir fabric-server
cd fabric-server
```

## Step 2: Download the Fabric Server JAR

[Fabric](https://fabricmc.net/use/server/) provides a Meta API that lets you
download the server JAR directly — no separate installer needed. The URL follows
this pattern:

```
https://meta.fabricmc.net/v2/versions/loader/{minecraft_version}/{loader_version}/{installer_version}/server/jar
```

For Minecraft 26.2 with Fabric Loader 0.19.3:

```bash
curl -OJ https://meta.fabricmc.net/v2/versions/loader/26.2/0.19.3/1.1.1/server/jar
```

The downloaded file will be named something like `fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar`.

## Step 3: Accept the EULA

Before the server can start, you need to accept the End User License Agreement:

```bash
echo "eula=true" > eula.txt
```

## Step 4: Install the Fabric API

The [Fabric API](https://modrinth.com/mod/fabric-api) is the foundation of
almost all Fabric mods. Without it, most addons simply will not work.

```bash
mkdir -p mods
cd mods
curl -OJ "https://cdn.modrinth.com/data/P7dR8mSH/versions/Cpy2Px2f/fabric-api-0.154.0%2B26.2.jar?mr_download_reason=standalone&mr_game_version=26.2&mr_loader=fabric"
cd ..
```

> **Important:** The URL contains `&` characters — always wrap it in quotes, or
> the shell will break the command. If the filename contains URL-encoded
> characters (`%2B` instead of `+`), rename it:

```bash
mv "fabric-api-0.154.0%2B26.2.jar" "fabric-api-0.154.0+26.2.jar"
```

## Step 5: Create a Start Script

Create a `start.sh` for convenient server startup:

```bash
#! /bin/bash
java -Xmx4G -Xms2G -jar fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar nogui
```

Make it executable:

```bash
chmod +x start.sh
```

Adjust the RAM values (`-Xmx`, `-Xms`) to your host. With 4 GB max and 2 GB
starting, it ran stable with all mods and four players — for a larger mod list
or more simultaneous players, I would plan for 6 GB (`-Xmx6G`).

## Step 6: Start the Server in the Background with tmux

For long-term operation I recommend `tmux` — the server keeps running even when
you close the terminal:

```bash
tmux new -s fabric-server
cd ~/minecraft/fabric-server
./start.sh
```

Detach the session (`Ctrl+B`, then `D`), reattach with `tmux attach -t
fabric-server`, list all sessions with `tmux ls`. Stop the server cleanly with
the `/stop` command in the console.

## Configuration: server.properties

On first start, Fabric generates a `server.properties` with default values. The
most important tweaks:

```properties
difficulty=normal
level-name=your-world
max-players=6
motd=§2Your Server §8| §fMinecraft Fabric §a❤
server-port=25566
```

If you run a Paper server on the same host, choose a different port (default is
25565). The MOTD supports color codes — `§2` is dark green, `§a` light green,
`§f` white, `§l` bold, `§o` italic.

### Granting Operator Permissions

On a fresh Fabric server, nobody has operator rights. In the server console (tmux):

```bash
op your-username
```

Repeat for additional players. Without OP rights, commands like `/gamerule` or
`/kick` will not work in the in-game chat — however, admin commands via the
server console (tmux) always work regardless of OP status.

### Server Icon

A custom server icon is a PNG at **exactly 64×64 pixels**, saved as
`server-icon.png` in the root directory (same level as `eula.txt`). Restart the
server after copying it for the icon to appear.

## Mod Selection: What Makes the Server Tick

Now for the fun part — the mods. My selection focuses on **family-friendly
gameplay**: farming, cooking, decoration, world generation, and performance. No
aggressive PvP or heavy tech mods.

Here are the highlights from my mod list:

### World Generation: Terralith

[Terralith](https://modrinth.com/mod/terralith) fundamentally changes world
generation — over 95 new biomes, canyons, floating islands, ocean trenches. The
best part: it uses **exclusively vanilla blocks**. The inventory stays
unchanged, only the landscape becomes more diverse.

> **Important:** Terralith **must be installed before world generation**. Adding
> it to an existing world risks chunk border errors and terrain seams. In our
> case, it was there from the start.

Since Terralith does not register new blocks or items, it only needs to be
installed on the **server** — the client technically does not know Terralith is
running. The additional dependency **Lithostitched** (library mod for world
generation configuration) is also required.

### Farming & Cooking: Farmer's Delight + Rustic Delight + Ube's Delight

[Farmer's Delight](https://modrinth.com/mod/farmers-delight-refabricated) is the
heart of the farming gameplay: new crops, kitchen appliances, dishes, and a
dedicated cooking system. Building on that:

- **[Rustic Delight](https://modrinth.com/mod/rustic-delight)** — pancakes (6
  flavors), coffee, peppers, cotton, calamari
- **[Ube's Delight](https://modrinth.com/mod/ubes-delight)** —
  Philippine-inspired: ube (purple yam), garlic, ginger, ube milk tea, halo
  halo, and more

All three mods are additive — they add new content without changing the base
game. Vanilla items keep their original function and gain additional recipe
possibilities.

### Decoration: Beautify + Storage Delight + Too Many Paintings

For visually appealing builds:

- **[Beautify Refabricated](https://modrinth.com/mod/beautify-refabricated)** —
  hanging pots, blinds, picture frames, new light sources (bamboo lanterns,
  candelabras), trellises, and more
- **[Storage Delight](https://modrinth.com/mod/storage-delight)** — drawers,
  bookshelves with doors, glass cabinets, single-door wardrobes
- **[Too Many Paintings](https://modrinth.com/mod/too-many-paintings)** —
  significantly more paintings with a searchable selection GUI

### Comfort: Comforts + Sit Anywhere + JourneyMap

- **[Comforts](https://modrinth.com/mod/comforts)** — sleeping bags and hammocks
  to skip day/night cycles
- **[Sit Anywhere!](https://modrinth.com/mod/sit-anywhere!)** — sit on almost
  any block (stairs, fences) with right-click
- **[JourneyMap](https://modrinth.com/plugin/journeymap)** — minimap in-game
  plus web map in the browser (port 8080)

### Performance: Lithium + Spark + Better Fabric Console

- **[Lithium](https://modrinth.com/mod/lithium)** — optimizes internal server
  logic (mob AI, redstone, world ticking) for better performance
- **[Spark](https://modrinth.com/mod/spark)** — profiling tool to diagnose lag
  spikes and TPS drops
- **[Better Fabric Console](https://modrinth.com/mod/better-fabric-console)** —
  colorized log output and tab completion in the server console

> **Warning:** Better Fabric Console additionally requires
> [adventure-platform-fabric](https://modrinth.com/mod/adventure-platform-mod)
> as a dependency. Without it, the mod loads without color output.

### Technical: Carpet + The Möbius Automata

For redstone and technical enthusiasts:

- **[Carpet](https://modrinth.com/mod/carpet)** — additional server rules, debug
  tools, redstone analysis helpers
- **[The Möbius Automata](https://modrinth.com/mod/the-mbius-automata)** — a bot
  mod built on Carpet that automates player hunting, building, and mining

### Recipe Browser: JEI

[JEI (Just Enough Items)](https://modrinth.com/mod/jei) shows all recipes and
item uses directly in the inventory — especially helpful with Farmer's Delight.
Since Minecraft 1.21.2, recipes are synchronized server-side, so JEI must be
installed on **both server and client**.

### Server Analytics: Plan

[Plan | Player Analytics](https://modrinth.com/plugin/plan) provides a web
dashboard with playtime stats, login history, and server performance trends.
Accessible on your local network at port 8804.

## Installing Mods on the Client

Unlike resource packs, Fabric mods are **not automatically** distributed to
clients. Every mod that adds new blocks or items must be **manually installed on
each client** in the exact same version.

Using the **Prism Launcher** makes this easy: Mod management → search for mod →
add matching version. The rule of thumb:

- **New blocks/items** (e.g., Farmer's Delight) → server **and** client
- **World generation or balance** (e.g., Terralith, Lithium) → server only
- **Server console / analytics** (e.g., Better Fabric Console, Plan) → server only

If a mod is missing or the version does not match, the client shows an error
message listing the missing mods when trying to connect.

## Automatically Updating Mods

With over 20 mods, manually checking for updates becomes tedious. I wrote a bash
script `check-updates.sh` that compares all `.jar` files in the `mods` folder
against the **Modrinth API** using SHA1 hashes:

```bash
./check-updates.sh
```

The script shows an overview (checked / up to date / updates available) and asks
whether found updates should be installed directly. Old files are backed up via
`mv`, and the backup is deleted only on successful download.

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

> **Important:** Stop the server before running the script — never replace a
> `.jar` file while it is loaded. The script requires `jq` (`apt install jq`).

## Conclusion

Running a Fabric server alongside a PaperMC server is straightforward: separate
directory, Fabric loader via Meta API, Fabric API as the foundation, and then
add mods to your heart's content. The initial setup takes less than 30 minutes —
everything after that is mod selection and configuration.

For me, the biggest win was the combination of Terralith (visually diverse
world) and the Delight mods (relaxed farming and cooking). This gives us a
server the whole family can play on — without aggressive gameplay changes. As
for the PaperMC server, I will keep it as a backup for now and eventually remove
it.

If you have questions or run your own Fabric server: let me know. I welcome
comments and tips for mod configuration.

Best regards,  
Sebastian

{{< translation-note >}}
