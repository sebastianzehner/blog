---
title: "Cactus Comments – Blog Comments Powered by Your Own Matrix Server"
summary: How I integrated Cactus Comments – a decentralized, tracking-free commenting system built on my own Matrix server – into my Hugo blog, including the client build, appservice setup, and Catppuccin styling.
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

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2026-04-18
  time: "18:06:00"
---

Comment systems like Disqus are convenient, but they come with the added burden of tracking, advertising, and external dependencies. Cactus Comments works differently: comments are stored directly in Matrix rooms on your own home server.

In the [previous article](https://sebastianzehner.com/de/posts/self-hosting-matrix-homeserver-synapse/), I showed you how to set up Synapse using Docker and how to manage your own Matrix home server. Today, we’ll build on that: with **Cactus Comments**, each blog post will have its own dedicated Matrix chat room. Readers can leave comments without having to register with a third-party service, and I will have full control over my data.

## What is Cactus Comments?

[Cactus Comments](https://cactus.chat/) is a federated commenting system for the open web that uses the Matrix protocol as its backend. The concept is quite simple: For each blog post, a corresponding Matrix room is automatically created. Anyone who wants to leave a comment logs in using their Matrix account—this can be an account on `matrix.org`, my own server, or any other Matrix-hosting service. Thanks to the federation mechanism!

The system consists of two parts:

- **Cactus Appservice** – a Python service that runs as a Matrix bot (here: `@cactusbot`) on the home server and is responsible for managing the rooms.
- **Cactus Client** is a JavaScript/Elm-based web application that is embedded within the blog to render the comment form.

## Prerequisites

- A running Synapse home server (my guide for setting it up: [Custom matrix-based home server using Synapse](https://sebastianzehner.com/de/posts/self-hosting-matrix-homeserver-synapse/))
- Docker and Docker Compose
- Node.js and npm (for building the client-side code)
- A Hugo website

## Building the Cactus Client

The Cactus Client is not provided as a finished bundle file; it must be built manually. I also want to keep a local copy of it in my own Forgejo installation, rather than relying on GitLab.

Clone the repository and mirror it to Forgejo:

```bash
git clone https://gitlab.com/cactus-comments/cactus-client.git
cd cactus-client
 
git remote rename origin gitlab
git remote add origin https://git.techlab.icu/sebastianzehner/cactus-client.git
 
git push origin --all
git push origin --tags
```

Run the build:

```bash
npm install
npm run build
```

> If you don’t already have your own Forgejo, you can skip the mirroring step.

### Possible error: The Elm package is corrupted

During the first attempt at building, the following error occurred for me:

```
🚨  CORRUPT PACKAGE DATA
I downloaded the source code for ryannhg/date-format 2.3.0 from:
    https://github.com/ryannhg/date-format/zipball/2.3.0/
But it looks like the hash of the archive has changed since publication.
```

The `ryannhg/date-format` package has had its hash changed since it was released, which is a known issue with Elm dependencies when the package author moves the version tag at a later date. The solution is to download the package manually and place it in the correct location.

```bash
cd ~/.elm/0.19.1/packages/ryannhg/date-format/2.3.0/
curl -L "https://github.com/ryannhg/date-format/zipball/2.3.0/" -o package.zip
unzip package.zip
mv ryan-haskell-date-format-b0e7928/* .
rm -rf ryan-haskell-date-format-b0e7928 package.zip
```

Then built it again—this time successfully:

```
✨  Built in 3.73s.
 
dist/cactus.js        155.95 KB
dist/style.css          6.96 KB
```

## Setting up the AppService

### Step 1: Generate tokens

The AppService requires two random tokens for authentication between Synapse and Cactus.

```bash
cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 2
```

The first line of the output will be `as_token`, and the second one will be `hs_token`. Make sure to note both of them carefully.

### Step 2: Create the registration file for Synapse

```bash
nvim ~/docker/synapse/files/cactus.yaml
```

Add the following lines:

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

This file tells Synapse that there is an AppService named `cactusbot` which manages all room aliases prefixed with `#comments_`.

### Step 3: Add content to the homeserver.yaml file

```bash
nvim ~/docker/synapse/files/homeserver.yaml
```

Add the following lines:

```yaml
app_service_config_files:
  - "/data/cactus.yaml"
 
allow_guest_access: true
use_appservice_legacy_authorization: true
enable_authenticated_media: false
 
public_baseurl: "https://matrix.your-domain.com"
```

> **Important:** The `/data/cactus.yaml` path is the path *inside* the Synapse container. In my case, `~/docker/synapse/files/` is mounted as `/data`.

> **Security Note:** The settings `allow_guest_access: true`, `use_appservice_legacy_authorization: true`, and `enable_authenticated_media: false` are requirements of the Cactus Appservice and they relax certain security measures implemented by Synapse. To avoid this, the Cactus client would need to be extended accordingly; however, this is beyond the scope of this documentation.

### Step 4: Setting environment variables for Cactus

```bash
nvim ~/docker-compose/synapse/cactus.env
```

Add the following lines:

```env
CACTUS_HS_TOKEN=YOUR_HS_TOKEN
CACTUS_AS_TOKEN=YOUR_AS_TOKEN
CACTUS_HOMESERVER_URL=http://synapse:8008
CACTUS_USER_ID=@cactusbot:matrix.your-domain.com
```

### Step 5: Expanding Docker Compose

In the existing `docker-compose.yml` for Synapse, I am adding the Cactus service:

```yaml
  cactus:
    image: cactuscomments/cactus-appservice:latest
    container_name: cactus
    env_file: cactus.env
    restart: unless-stopped
    networks:
      - synapse
```

Cactus is placed in the `synapse` network so it can reach the Synapse container directly at `http://synapse:8008`.

### Step 6: Start

```bash
cd ~/docker-compose/synapse
docker compose down
docker compose up -d synapse
# wait for Synapse to become healthy
docker compose up -d cactus
```

For verification:

```bash
docker logs cactus --tail 50
docker logs synapse --tail 50
```

## Registering the website with Cactus

Before Cactus can create comment sections for my blog, I need to register my website with `cactusbot`. This can be done directly through [Element](https://app.element.io).

Open a new chat with `@cactusbot:matrix.your-domain.com` and enter the following message:

```
register <websitename>
```

If everything is set up correctly, the bot will respond with an acknowledgment. The successful execution of the process can be seen in the container logs as follows:

```
INFO in app: Registration complete
INFO in app: Created site    name='websitename' owner='@your_name:matrix.your-domain.com'
INFO in app: Power level changed, replicating    room='#comments_websitename:matrix.your-domain.com'
```

## Hugo Integration

### Copy the client files

```bash
cd ~/hugo/cactus-client
cp dist/cactus.js ~/hugo/blog/static/
cp dist/style.css ~/hugo/blog/static/cactus.css
```

### Creating a shortcode

```bash
nvim ~/hugo/blog/layouts/shortcodes/chat.html
```

My shortcut loads the Cactus Client and initializes the comment section. I’ve also customized it to match my **Catppuccin** color scheme, both for the light “Latte” and dark “Mocha” themes.

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

All available configuration options for `initComments` are described in [Cactus Client Documentation](https://cactus.chat/docs/client/introduction/#configuration).

### Adding a comment section into a blogpost

From now on, a single line will be enough to add a comment section under an article.

```
{{</* chat cactus-comments */>}}
```

The parameter ``cactus-comments`` is the name of the matrix space for this article. Each space automatically gets the alias ``#comments_websitename_cactus-comments:matrix.your-domain.com``. I can use a different space name for each article or the same name for all articles; this depends on whether I want to consolidate comments per article or globally.

### Changes are being published

```bash
git add layouts/shortcodes/chat.html static/cactus.css static/cactus.js
git commit -m "migrate Cactus Comments to self-hosted matrix.your-domain.com"
git push origin
```

## Conclusion

What convinced me about Cactus Comments is the following: there is no external database, no third-party tracking, and no JavaScript payloads from foreign domains.

The comments are stored as regular matrix events in my own synapses, secured using my usual restic backup method, and are versioned and portable.

At the same time, anyone who has a Matrix account can comment immediately, regardless of which home server their account is located on. And those who don’t have an account yet can create one in just a few minutes by using `matrix.org`.

This is the web as it should be.

---

Questions or comments? Feel free to write to me directly via Matrix: `@sebastian:matrix.techlab.icu`, or just leave a comment below. It will end up right in my Matrix as well.

Best regards, Sebastian

{{< chat self-hosting-matrix-homeserver-synapse >}}
