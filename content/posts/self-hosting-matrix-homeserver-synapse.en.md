---
title: "Self-Hosting Your Own Matrix Homeserver with Synapse – Take Back Control of Your Data"
summary: In this article, I set up my own Matrix homeserver using Synapse and Docker Compose. Alongside a brief introduction to the decentralized Matrix protocol, I walk through the complete installation with PostgreSQL, Traefik, and Cloudflare Tunnel.
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

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2026-04-08
  time: "12:52:14"
---

*Decentralization, data privacy, and full control over your communications—all of this is easier to achieve with Synapse and Docker than you might think.*

## What is Matrix – and why is it different?

Most of the messaging apps we use daily – WhatsApp, Telegram, Signal, iMessage and more – have one thing in common: they are centrally organized. This means that your messages are transmitted through servers that you don’t have control over. You rely on a company to maintain the infrastructure, protect your data, and keep the service running. What happens if that company is sold, changes its privacy policies, or simply decides to shut down the service?

[Matrix](https://matrix.org) solves this problem using a different approach: it’s an **open, decentralized communication protocol**. Similar to how email worked in the past, everyone can run their own server, and all these servers can communicate with each other – this is called **federation**. Your account on `@you:your-server.com` can easily send messages to someone on `@others:matrix.org`, just like you can send an email from Gmail to an Outlook address.

This means:

- **No dependence** on a single provider.
- **Full end-to-end encryption** (optional, but recommended)
- **Self-determination:** You decide who can create an account on your server.
- **Bridges:** Matrix can be integrated with services like WhatsApp, Telegram, Discord, Signal, and many others – all within a single client.

The most well-known matrix-based home server is Synapse, developed by Element (formerly New Vector). It is written in Python, has extensive documentation, and can be easily hosted independently using Docker.

## Why host Synapse yourself?

Those who operate their own Synapse server gain several advantages at once:

**Data privacy:** Your messages and media are stored on your own infrastructure. However, through the federation system, space-related events can also be replicated on the servers of other participants. You retain full control over your own data and are not subject to the terms and conditions of any commercial provider.

**Backup Control**: There are no longer any app-specific backup solutions. You ensure the safety of the PostgreSQL database and the media directory according to your own rules—for example, using [restic](https://restic.net/).

**Your own user accounts:** You can create accounts for your family, friends, or a community. The server belongs to you.

**Bridges as a central hub:** Instead of opening five different apps, you can integrate WhatsApp, Telegram, or Discord into your preferred Matrix client using Matrix Bridges. One client for everything.

**Persistence**: As long as your server is running, your chat rooms and their histories will remain. No provider can take them away from you.

## Prerequisites

For this guide, you need:

- A Linux server (I’m using Alpine Linux) with Docker and Docker Compose.
- A reverse proxy - I use **Traefik**.
- A domain name - I’m using `matrix.techlab.icu`.
- Optional: A Cloudflare tunnel for external access.

## Installation using Docker Compose

### Create a directory structure

First, we create the necessary directories:

```bash
mkdir -p ~/docker-compose/synapse
mkdir -p ~/docker/synapse
mkdir -p ~/docker/synapse/files
mkdir -p ~/docker/synapse/db-data

nvim ~/docker-compose/synapse/docker-compose.yml
```

> This corresponds to my personal directory structure for all Docker containers: the volume data is stored in `~/docker`, and the Compose configuration data is stored in `~/docker-compose`. This keeps everything organized, and I regularly back up these two directories using restic. I might even write a separate article about it.

### docker-compose.yml

Here is my productive configuration with Synapse, PostgreSQL, and traffic integration:

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

A few notes regarding the configuration:

- Synapse is assigned a **fixed IP address** in the `proxy` network, so that traffic can reliably reach it.
- The `block-synapse-static` middleware prevents `/_matrix/static` from being publicly accessible; only the standard welcome page is available there, which no one outside needs. The path is redirected internally, resulting in a 404 error.
- PostgreSQL is initialized using `lc-collate=C` and `lc-ctype=C`; this is an official requirement from Synapse for proper database operations to function correctly.

### Generating the configuration file

Synapse provides a generator for the initial ``homeserver.yaml``. We start the container once in generating mode and specify our own domain name.

```bash
docker run -it --rm \
  --mount type=volume,src=synapse-data,dst=/data \
  -e SYNAPSE_SERVER_NAME=matrix.techlab.icu \
  -e SYNAPSE_REPORT_STATS=no \
  matrixdotorg/synapse:latest generate
```

The container stores the generated files in a Docker volume. As the root user, we copy them to our working directory:

```bash
sudo -i
cd /var/lib/docker/volumes/synapse-data/_data/
cp * /home/user/docker/synapse/files
exit

cd /home/user/docker/synapse/files
sudo chown user: *
```

### Modify the homeserver.yaml file

Now we open ``homeserver.yaml`` and configure the database connection. We replace the default SQLite configuration with the PostgreSQL configuration block:

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

The hostname `synapse-db` corresponds to the container name from `docker-compose.yml`; Docker resolves this hostname internally.

### Start the server

```bash
cd ~/docker-compose/synapse
docker compose up -d
```

After starting, the following message should appear under `https://matrix.techlab.icu`:

```
It works! Synapse is running
Your Synapse server is listening on this port and is ready for messages.

To use this server you'll need a Matrix client.

Welcome to the Matrix universe :)
```

## External access via Cloudflare Tunnel

To ensure that the server can be accessed from outside the home network as well, I set up a Cloudflare Tunnel. A public hostname is created within this setup.

- Hostname: `matrix`
- Domain: `techlab.icu`
- Service Type: `https`
- URL: `matrix.techlab.icu`

Important: The service type `https` ensures that the connection from Cloudflare’s Edge to the target server (Traefik) remains completely encrypted. Internally, Pi-hole resolves the DNS query `matrix.techlab.icu` to obtain the IP address of the Traefik server.

## Activate the Federation

Matrix relies on the ability for different servers to communicate with each other seamlessly. In order for my server to be able to communicate with `matrix.org` and other servers, the Federation feature must be enabled. By default, Synapse uses port 8448 for this purpose; however, I am redirecting communications to port 443 instead, as this is the port already used by the Cloudflare tunnel.

Inside the `homeserver.yaml`:

```yaml
# allow room access over federation
matrix_synapse_allow_public_rooms_over_federation: true

# enable federation on port 443
serve_server_wellknown: true
```

The status can be checked using [Matrix Federation Tester](https://federationtester.matrix.org/). A successful report looks like this:

```
Got 4 connection reports.
Homeserver version: Synapse 1.150.0

[IPv4-Address]:443  ✓ Success
[IPv4-Address]:443  ✓ Success
[IPv6-Address]:443  ✓ Success
[IPv6-Address]:443  ✓ Success
```

Practical note: Even after the Federation Tester shows all green indicators, it may still take a while before communication with external servers becomes reliable. A bit of patience is required, but after a few minutes, everything should work smoothly.

## Create an Administrator Account

We create the first user, who will also act as the administrator, directly within the running container.

```
docker exec -it synapse register_new_matrix_user http://localhost:8008 -c /data/homeserver.yaml
```

The command interactively asks for the username, password, and whether the account should have admin privileges.

## Matrix Clients

### Element Web & Desktop

The most well-known Matrix client is **Element**. It is available as a web app at [app.element.io](https://app.element.io), as well as a desktop app for macOS, Windows, and Linux.

The first time you log in to your own server, you need to manually set the server URL to your own domain. On macOS, it’s possible that the client will only work fully after the operating system performs a security check. macOS will ask whether the app is allowed to access the local network. Please grant the permission and then restart the client.

### Verifying Devices

Matrix supports cross-signing for device verification. If you want to communicate securely with someone, you can verify their device. On both sides, a window appears displaying identical symbols and terms that need to be compared. If the symbols match and both parties confirm this, the other person’s device is considered trustworthy, and the communication is then end-to-end encrypted.

### Setting Up Key Recovery

During the first login, you will be prompted to set up key recovery. This step should not be skipped. As part of this process, a recovery key will be generated, which you must store securely. I have saved it in [KeePassXC](https://keepassxc.org) both as a protected entry and as a exported file.

Without this key, encrypted messages will be irretrievably lost after a device is lost or restarted, especially if there is no active session in place.

### Iamb – Matrix in the terminal

For everyone who doesn’t want to leave their terminal: [Iamb](https://iamb.chat) is a full-fledged matrix client with a terminal-style interface, inspired by Vim’s keybinding conventions. Those who use Neovim and Tmux will feel right at home immediately.

## Backup Strategy

Synapse requires two things to be backed up:

1. The PostgreSQL database at `~/docker/synapse/db-data/`: This contains all the matrix events – messages, room history, metadata, etc.

2. The files under `~/docker/synapse/files/`: configuration settings, uploaded media files, and – most importantly – the **Signing Key**.

The Signing Key is the cryptographic identifier for a server within the Matrix network. If it is lost, other servers will no longer trust that server; the entire federation will collapse, and you will need to set up the server from scratch. For this reason, I have stored it in my password manager, in addition to the backup file created by restic.

> I automatically backup the entire `~/docker/` directory using restic, ensuring that both of those critical paths are always included.

## Future outlook: Bridges and Cactus Comments

This is just the beginning. The Matrix, with its open protocol, provides an excellent foundation for further integrations.

**Bridges** allow for the integration of other messaging services. If someone wants to route their WhatsApp, Telegram, or Discord communications through their own Matrix server, this can be achieved using the corresponding bridge containers. All the messages are then consolidated in a single Matrix client.

I’m not using any Bridges right now, but I’m considering setting up an email bridge. Unfortunately, it’s not possible to run a dedicated email server in a home lab setup without a fixed IP address; without the trust of major providers, emails will quickly end up in the spam folder or be rejected altogether. That’s why I’m particularly excited about being able to regain at least some of that freedom with Matrix.

**Cactus Comments** uses Matrix as its backend for blog comments. For each type of blog post, there is a dedicated Matrix chat room where readers can leave comments – without the need to create an account with an external commenting system. For more information on this, see a separate article. Cactus Comments is already in use on my blog, running on my own Synapse server.

Do you have any questions regarding your own Synapse installation? Feel free to write to me—preferably directly through Matrix. My address is `@sebastian:matrix.techlab.icu`; you can also leave a comment, which will be sent to my Matrix account as well.

Best regards, Sebastian

{{< chat self-hosting-matrix-homeserver-synapse >}}
