+++
title = 'Selbst gehostetes Social Media Management mit Mixpost'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Ich hatte die Idee, mein Engagement in den sozialen Medien zu vereinfachen und das ohne viel Geld oder gar monatliche Abonnementgebühren zu bezahlen. Dabei fand ich Mixpost als eine selbst gehostete Lösung.'
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
    alt = 'Beitragsbild von Selbst gehostetes Social Media Management mit Mixpost'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Ich hatte die Idee, mein Engagement in den sozialen Medien zu vereinfachen und das ohne viel Geld oder gar monatliche Abonnementgebühren zu bezahlen. Ich fand Mixpost als selbst gehostete Lösung für die Verwaltung sozialer Medien. Also habe ich das ganze mal aufgesetzt und die letzten Tage getestet. Heute möchte ich meine Erfahrungen mit Mixpost auf einem lokalen Rechner bei mir zu Hause in Paraguay teilen.

Die Installation ist mit Docker Containern einfach zu handhaben. Zuerst habe ich versucht Mixpost auf meinem Synology NAS zu installieren, da dort die Docker Container normalerweise im Synology Container Manager laufen, nur Mixpost leider nicht.

Es gab ein Problem mit dem MySQL-Datenbankcontainer. Da eine NAS Installation nicht unterstützt wird, habe ich eine virtuelle Maschine mit Ubuntu auf meinem Mac Studio erstellt und die Dockerumgebung dort installiert.

Ich habe das gleiche Setup noch einmal gemacht und es hat sofort funktioniert. Aber es war nicht perfekt und ich musste einige Verbesserungen und manuelle Einstellungen für meine Anforderungen vornehmen.

Außerdem benötigte ich einen neuen Domainnamen und einen externen Zugang vom Internet aus. Ich bin nicht in der Lage, bestimmte Ports an meinem Standort weiterzuleiten aber ich habe alternative Möglichkeiten herausgefunden und das hat bei mir funktioniert. Ich werde dir genau zeigen was ich gemacht habe.

## Was sind meine Mindestanforderungen?

- Mixpost läuft auf einem lokalen Rechner
- Spätere Migration auf einen lokalen Server
- Keine Einschränkungen oder monatlichen Abonnementgebühren
- Verbindung zu den meisten beliebten Social Media Accounts
- Domainname mit externem Zugriff
- Domainname mit internem Zugriff
- Sicheres HTTPS für alle Verbindungen
- Einfache Sicherung und Wiederherstellung der Datenbank
- Einfacher Umzug oder Verwendung eines anderen Servers

## Wie wird Mixpost installiert?

Die [Mixpost Dokumentation](https://docs.mixpost.app/) ist sehr hilfreich, wenn man Mixpost auf einem Linux Rechner mit Docker installiert. Ich habe mit der kostenlosen Version Mixpost Lite begonnen. Ja, die Mixpost Pro Version wird eine einmalige Zahlung beinhalten aber ich denke das ist sie wert.

Ich begann mit der Docker Installation, nachdem ich meine virtuelle Maschine mit Ubuntu eingerichtet und mich mit SSH über mein Terminal verbunden hatte. Ich folgte einfach den fünf einfachen Schritten in der [Dokumentation](https://docs.mixpost.app/lite/installation/docker), um Docker und Mixpost auf meiner lokalen virtuellen Maschine zu installieren.

Ich habe Traefik noch nie benutzt und es war ein bisschen verwirrend für mich aber jetzt ist es ok und funktioniert gut.

## Meine Konfiguration für die Docker Container

Im Moment sieht meine docker-compose.yml Datei wie folgt aus:

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

Ich habe einige Änderungen für die Verschlüsselung vorgenommen, da meine Installation lokal ist und ich Letsencrypt nicht verwenden kann. Ich habe die Konfiguration für Letsencrypt im Traefik Container gelöscht und stattdessen eine dynamische Konfiguration verwendet.

Damit kann ich meine eigenen Zertifikate installieren und die Laufwerke für die dynamische Konfiguration und mein Zertifikat mit Schlüsseldatei einbinden.

Ich habe in der Vergangenheit einen [Blogpost](/de/posts/how-to-build-a-minimalistic-and-self-hosted-website-for-free/) geschrieben und beschrieben, wie ich meine eigenen SSL-Zertifikate mit OpenSSL für lokale Webdienste signiere.

Bei dem Mixpost Conatiner habe ich auch eine zweite Domain für den externen Zugriff hinzugefügt. `APP_DOMAIN` ist also meine lokale Domain und `APP_DOMAIN_WEB` ist meine externe Domain.

Meine .env Datei:

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

Hier habe ich nur eine neue Variable für meinen externen Domainnamen hinzugefügt.

Meine certs-traefik.yml Datei:

```YAML
tls:
  certificates:
    - certFile: /etc/certs/mixpost.lan.crt
      keyFile: /etc/certs/mixpost.lan.key
```

Ich verwende meine eigenen selbstsignierten SSL-Zertifikate und habe daher die .crt- und .key-Datei in den Traefik Container integriert.

Mit dieser Konfiguration kann ich mit meiner lokalen Domain auf das Mixpost Dashboard zugreifen und HTTPS funktioniert mit meinem selbstsignierten Zertifikat. Was musste ich nun für den externen Zugriff verändern?

## Cloudflare Zero Trust Tunnel

Zuerst habe ich meine neue Domain mit Cloudflare verbunden und einen Tunnel erstellt, um zu meinem lokalen Mixpost Dashboard zu gelangen. Ich installierte auch den Connector auf meiner virtuellen Maschine und die Einrichtung war wirklich einfach mit nur einem weiteren Docker Container.

SSL-Zertifikate werden automatisch von Cloudflare konfiguriert und die HTTPS-Verbindung funktioniert wenn ich Cloudflare sage, dass das lokale Zertifikat ignoriert werden soll.

Nun ist mein lokales Mixpost Dashboard über das Internet erreichbar und ich kann im nächsten Schritt die Social Media Accounts einrichten.

## Social Media Accounts einrichten

In der selbst gehosteten Mixpost Lite Version sind nur Verbindungen mit Facebook Pages, X und Mastodon Accounts möglich. In den [Docs](https://docs.mixpost.app/services/) sind Anleitungen für Drittanbieterdienste beschrieben und leicht nachvollziehbar.

Ich habe alle möglichen Verbindungen mit meinen Social Media Accounts eingerichtet und ein paar Posts gestestet. Einzelne Posts und mehrere Posts auf drei Plattformen gleichzeitig und alles funktionierte wie erwartet. Es ist möglich, verschiedene Versionen in einem Beitrag zu erstellen und das ist gut, denn X erlaubt nur 280 Zeichen und andere 500 oder 5000 Zeichen.

Ich möchte auch Youtube, TikTok, Instagram und Pinterest mit Mixpost nutzen. Dafür muss ich die Pro Lizenz kaufen und das werde ich später nachholen.

## Sicherung der MySQL Datenbank

Ich habe die Datenbank mit folgendem Befehl gesichert:

```BASH
docker exec CONTAINERNAME /usr/bin/mysqldump -u root --password=ROOTPASSWORD DATABASE > backup.sql
```

Oder dasselbe aber komprimiert mit diesem Befehl:

```BASH
docker exec CONTAINERNAME /usr/bin/mysqldump -u root --password=ROOTPASSWORD DATABASE | gzip > backup.sql.gz
```

> Tipp: Speichere die .sql oder .sql.gz Datei an einem sicheren Ort!

## Wiederherstellung der MySQL Datenbank

Um die Datenbank wiederherzustellen verwende den folgenden Befehl:

```BASH
cat backup.sql | docker exec -i CONTAINERNAME /usr/bin/mysql -u root --password=ROOTPASSWORD DATABASENAME
```

Oder falls komprimiert mit diesem Befehl:

```BASH
zcat backup.sql.gz | docker exec -i CONTAINERNAME /usr/bin/mysql -u root --password=ROOTPASSWORD DATABASENAME
```

## Was kommt als nächstes?

Als nächstes möchte ich eine neue virtuelle Maschine erstellen und die Mixpost Installation wiederherstellen, um zu prüfen, ob alles wie erwartet funktioniert.

Dann werde ich die Pro Version kaufen und meine lokale Installation aktualisieren.

Später werde ich auf einen anderen lokalen Server umziehen und meine Mixpost Installation als produktive Anwendung laufen lassen und weiterhin Beiträge auf verschiedenen Social Media Accounts mit Mixpost veröffentlichen.

Wenn du irgendwelche Fragen hast, lass es mich bitte in den Kommentaren wissen.

Liebe Grüße Sebastian

{{< chat self-hosted-social-media-management-with-mixpost >}}
