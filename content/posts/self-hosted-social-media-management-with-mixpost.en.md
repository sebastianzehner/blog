+++
title = 'Self-hosted Social Media Management with Mixpost'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'I had the idea to simplify my social media engagement but without paying a lot of money or even monthly subscription fees. I found Mixpost as a self-hosted social media management solution. Today I share my experience.'
date = 2024-08-25T18:07:53-04:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2024-08-25T18:07:53-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Social Media', 'Mixpost', 'Simple Life']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/self-hosted-social-media-management-with-mixpost.webp'
    alt = 'Featured image from Self-hosted Social Media Management with Mixpost'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

I had the idea to simplify my social media engagement but without paying a lot of money or even monthly subscription fees. I found Mixpost as a self-hosted social media management solution. Therefore I set this hole thing up and tested the last days. Today I want to share my experience with Mixpost on a local machine at my home in Paraguay.

The installation is easy to handle with docker containers. First I tried to install Mixpost on my Synology NAS because normally docker containers run within Synology Container Manager but Mixpost didn't.

There was an issue with the MySQL database container. Because a NAS installation is not supported I created a Virtual Machine with Ubuntu on my Mac Studio and installed the docker environment there.

I did the same setup again and it worked immediately. But it was not perfect and I had to make some improvements and manual settings for my requirements.

I also needed a new domain name and external access from the Internet. I am not able to forwarding some ports at my location but I found other possibilities and it worked for me. I will show you exactly what I did.

## What are my minimum requirements?

- Mixpost running on a local machine
- Later migrate to a local server
- No limits or monthly subscription fees
- Connect to most popular social media accounts
- Domain name with external access
- Domain name with internal access
- Secure HTTPS for all connections
- Easy database backup and restore
- Easy to move or use another server

## How to install Mixpost

The [Mixpost Documentation](https://docs.mixpost.app/) is very helpful when you install Mixpost on a Linux machine with docker. I started with the Mixpost Lite free version. Yes, the Mixpost Pro version will cost some one-time payment but I think it's worth.

Getting started with the Docker installation after I set up my Ubuntu virtual machine and connected via SSH in my terminal. I just followed the five simple steps in the [documentation](https://docs.mixpost.app/lite/installation/docker) to install Docker and Mixpost on my local virtual machine.

I never used traefik before and it was a little bit confuse for me but now it's ok and works fine.

## My setup files for the docker containers

At the moment my docker-compose.yml file looks like this:

```YAML
version: '3.1'

services:
    traefik:
      image: "traefik"
      restart: unless-stopped
      command:
        - "--api=true"
        - "--api.insecure=true"
        - "--providers.docker=true"
        - "--providers.docker.exposedbydefault=false"
        - "--entrypoints.web.address=:80"
        - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
        - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
        - "--entrypoints.websecure.address=:443"
        - "--providers.file.directory=/etc/traefik/dynamic" # for dynamic configuration
        - "--providers.file.watch=true" # for dynamic configuration
      ports:
        - "80:80"
        - "443:443"
        # - "8080:8080" # traefik dashboard disabled
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock:ro
        # Mount the dynamic configuration
        - ./certs-traefik.yml:/etc/traefik/dynamic/certs-traefik.yml
        # Mount the directory containing the certs for mixpost.lan
        - ../certs:/etc/certs/
    mixpost:
        image: inovector/mixpost:latest
        env_file:
            - .env
        ports:
            - "127.0.0.1:9000:80"
        labels:
          - traefik.enable=true
          - traefik.http.routers.mixpost.rule=Host(`${APP_DOMAIN}`) || Host(`${APP_DOMAIN_WEB}`)
          - traefik.http.routers.mixpost.tls=true
          - traefik.http.routers.mixpost.entrypoints=web,websecure
          - traefik.http.routers.mixpost.tls.certresolver=mytlschallenge
          - traefik.http.middlewares.mixpost.headers.SSLRedirect=true
          - traefik.http.middlewares.mixpost.headers.STSSeconds=315360000
          - traefik.http.middlewares.mixpost.headers.browserXSSFilter=true
          - traefik.http.middlewares.mixpost.headers.contentTypeNosniff=true
          - traefik.http.middlewares.mixpost.headers.forceSTSHeader=true
          - traefik.http.middlewares.mixpost.headers.SSLHost=`${APP_DOMAIN}`
          - traefik.http.middlewares.mixpost.headers.STSIncludeSubdomains=true
          - traefik.http.middlewares.mixpost.headers.STSPreload=true
          - traefik.http.routers.mixpost.middlewares=mixpost@docker
        volumes:
            - storage:/var/www/html/storage/app
            - logs:/var/www/html/storage/logs
        depends_on:
            - mysql
            - redis
        restart: unless-stopped
    mysql:
        image: 'mysql/mysql-server:8.0'
        environment:
            MYSQL_DATABASE: ${DB_DATABASE}
            MYSQL_USER: ${DB_USERNAME}
            MYSQL_PASSWORD: ${DB_PASSWORD}
        volumes:
            - 'mysql:/var/lib/mysql'
        healthcheck:
            test: ["CMD", "mysqladmin", "ping", "-p ${DB_PASSWORD}"]
            retries: 3
            timeout: 5s
        restart: unless-stopped
    redis:
        image: 'redis:latest'
        command: redis-server --appendonly yes --replica-read-only no
        volumes:
            - 'redis:/data'
        healthcheck:
            test: ["CMD", "redis-cli", "ping"]
            retries: 3
            timeout: 5s
        restart: unless-stopped

volumes:
    traefik_data:
      driver: local
    mysql:
        driver: local
    redis:
        driver: local
    storage:
        driver: local
    logs:
        driver: local
```

I did some changes for the encryption because my installation is local and I can't use letsencrypt. I deleted the config for letsencrypt at the traefik container and used a dynamic configuration instead.

Then I am able to install my own certificates and mount the volumes for dynamic configuration and my cert with key files.

I wrote a [blog post](/posts/how-to-build-a-minimalistic-and-self-hosted-website-for-free/) in the past and described how I sign my own SSL certificates with OpenSSL for local web services.

At the Mixpost conatiner I also added a secont Domain for external access. So APP_DOMAIN is my local domain and APP_DOMAIN_WEB is my external domain.

My .env file:

```YAML
# The name of your application.
APP_NAME=Mixpost

# Key used to encrypt and decrypt sensitive data. Generate this using the following tool:
# https://mixpost.app/tools/encryption-key-generator
APP_KEY=keyfrommixpostwebsite

# Debug mode setting. Set to `false` for production environments.
APP_DEBUG=false

# Your app's domain or subdomain, without the 'http://' or 'https://' prefix.
APP_DOMAIN=domain.local
APP_DOMAIN_WEB=external.domain.com

# Full application URL is automatically configured; no modification required.
APP_URL=https://${APP_DOMAIN}

# MySQL connection setup.
DB_DATABASE=mixpost_db
DB_USERNAME=mixpost_user
DB_PASSWORD=astrongpassword

# Specify the email address to be used for SSL certificate registration and notifications.
SSL_EMAIL=myemal@gmail.com
```

Here I only added a new variable for my external domain name.

My certs-traefik.yml file:

```YAML
tls:
  certificates:
    - certFile: /etc/certs/mixpost.lan.crt
      keyFile: /etc/certs/mixpost.lan.key
```

I am using my own self-signed SSL certificates and therefore I included the .crt and .key file to the traefik container.

With this setup I am able to access the Mixpost dashboard with my local domain and HTTPS works with my self-signed certificate. Now what I had to change for external access?

## Cloudflare Zero Trust Tunnel

First I connected my new domain with Cloudflare and created a tunnel to route to my local Mixpost dashboard. I also installed the connector on my virtual maschine and the setup was really easy with only one docker container more.

SSL certificates are automatically configured from Cloudflare and the HTTPS connection works, if I said to Cloudflare to ignore the local certificate.

Now my local Mixpost dashboard is reachable about the internet and I can configure the social media accounts in the next step.

## Configure Social Media accounts

In the self-hosted Mixpost Lite version only connections with Facebook Pages, X and Mastodon accounts are possible to use. In the [Docs](https://docs.mixpost.app/services/) are guides for third party services described and easy to follow.

I configured all possible connections with my social media accounts and tested a few posts. Single posts and multi posts using three platforms at the same time and all worked as aspected. It's allowed to create different versions in one post and that's nice because X only allows 280 characters and others 500 or 5000 characters.

I also want to use Youtube, TikTok, Instagram and Pinterest with Mixpost. Therefore I have to buy the Pro licence. I will do this later.

## Backup the MySQL database

I backuped the database with following command:

```BASH
docker exec CONTAINERNAME /usr/bin/mysqldump -u root --password=ROOTPASSWORD DATABASE > backup.sql
```

or same but compressed with this command:

```BASH
docker exec CONTAINERNAME /usr/bin/mysqldump -u root --password=ROOTPASSWORD DATABASE | gzip > backup.sql.gz
```

> Tip: Save the .sql or .sql.gz backup file on a secure place!

## Restore the MySQL database

To restore the database use following command:

```BASH
cat backup.sql | docker exec -i CONTAINERNAME /usr/bin/mysql -u root --password=ROOTPASSWORD DATABASENAME
```

or if compressd than this command:

```BASH
zcat backup.sql.gz | docker exec -i CONTAINERNAME /usr/bin/mysql -u root --password=ROOTPASSWORD DATABASENAME
```

## Whats next?

Next I want to create a new virtual machine and restore the Mixpost installion to prove if everything works as aspected.

Then I will buy the Pro version and upgrade my local installation.

Later I will move to another local server and run my Mixpost installation as a productive application and keep posting on different social media accounts with Mixpost.

If you have any questions please let me know in the comments.

Regards Sebastian

{{< chat self-hosted-social-media-management-with-mixpost >}}
