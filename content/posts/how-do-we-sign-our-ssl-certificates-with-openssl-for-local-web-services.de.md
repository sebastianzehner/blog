+++
title = 'Wie wir unsere SSL Zertifikate mit OpenSSL für lokale Webdienste signieren'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Ich dokumentiere in diesem Blogbeitrag, wie wir selbst signierte SSL-Zertifikate erstellen und sie sicher im lokalen Netzwerk verwenden. In meinem Homelab läuft auf einem älteren Raspberry Pi ein lokaler Webserver.'
date = 2024-07-31T20:53:58-04:00
lastmod = 2024-07-31T20:53:58-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['OpenSSL', 'HTTPS', 'Zertifikate', 'LAN']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true
+++

Ich dokumentiere hiermit, wie wir selbst signierte SSL-Zertifikate erstellen und sie sicher im lokalen Netzwerk verwenden können. Ich habe in meinem Homelab auf einem älteren Raspberry Pi einen lokalen Webserver installiert und möchte gerne, dass diese Webseiten eine sichere Verbindung über HTTPS im Browser anzeigen.

Konfiguriert wurde das einmal mit Apache2 aber auch mit einem Lighttpd Server, wo unter anderem meine Pi-Hole Installation läuft. Das Pi-Hole Admin Dashboard aber auch meine Intranet Webseite auf Apache2 sind inzwischen sicher über HTTPS zu erreichen. Wie wir das alles konfiguriert bekommen wird in der folgenden Dokumentation beschrieben.

Wir beginnen mit der Erstellung von SSL-Zertifikaten und setzen diese für die Absicherung unseres Webdienstes ein. Der Hauptgrund, warum ich mich überhaupt damit beschäftigt habe war die Tatsache, dass in meinem Browser „Nicht sicher“ mit einem Ausrufezeichen angezeigt wurde und das gefiel mir nicht.

Wir beheben dies heute und haben hinterher, nach allen erforderlichen Konfigurationen, eine sichere Verbindung mit dem Browser zum Webserver durch die Verwendung eines gültigen und selbst signierten Zertifikates.

## Was benötigen wir für die SSL-Zertifikate?

Das hängt von unserer Serverumgebung ab. Ich verwende bei mir einen Raspberry Pi mit Ubuntu 24.04 LTS und habe den Zugang über SSH mit dem Terminal auf meinem Mac Studio eingerichtet. Der SSH Zugang ist wichtig und wir brauchen OpenSSL auf dem Server installiert.

Wir prüfen mit dem Befehl `openssl version`, ob die Anwendung OpenSSL auf unserem Server bereits installiert ist und falls nicht, kann dies mit den folgenden zwei Befehlen einfach nachgeholt werden. Ich nutze bei mir übrigens die OpenSSL Version 3.0.13 vom 30. Januar 2024.

```
sudo apt-get update
sudo apt-get install openssl
```

Damit haben wir die notwendigen Voraussetzungen geschaffen, um mit den eigenen Zertifikaten zu beginnen.

## Unsere eigene SSL Zertifizierungsstelle für Root-Zertifikate (Root-CA)

Wir brauchen nicht nur ein Zertifikat auf unserem Server zu installieren, sondern müssen auch das SSL Root-Zertifikat bei unseren Client Benutzer-Rechnern einbinden, um die Vertrauenswürdigkeit des Serverzertifikates überprüfen zu können und erst danach wird auch im Browser eine sichere Verbindung angezeigt.

Installiere ich nur das Zertifikat auf dem Server, wird bei den Endgeräten, die auf den Webserver über einen Browser zugreifen möchten, immer noch ein ungültiges Zertifikat oder eine unsichere Verbindung angezeigt.

Ich muss daher am Ende auch das SSL Root-Zertifikat auf meinem Mac Studio einbinden, damit die Verbindung als sicher und vertrauenswürdig angezeigt wird. Wie man das genau bei MacOS macht, zeige ich ganz zum Schluss. Zusätzlich zeige ich das bei einem Windows Notebook, einem Android Smartphone und einem Apple iPad mit iOS bzw. dem iPadOS.

Ich benutze in meinem lokalen Netzwerk nur ein Root-Zertifikat und muss daher auch nur dieses eine Zertifikat auf den entsprechenden Endgeräten einbinden. Mit diesem Root-Zertifikat erstelle ich alle weiteren Zertifikate für meine Server. Erstmal aber nur eins für den Webserver und die Pi-Hole Installation auf meinem Raspberry Pi. Fangen wir jetzt mit der eigentlichen Arbeit an. Los geht's :rocket:

## Wir erstellen den privaten (Root) Schlüssel

Zuerst brauchen wir einen privaten Schlüssel auf unserer Zertifizierungsstelle. Bei mir ist das ebenfalls der Raspberry Pi mit seiner Ubuntu Linux-Installation. Grundsätzlich ist es egal, wo wir unsere Schlüssel erstellen. Ich mache das einfach alles auf dem gleichen Server und habe damit bisher keine Probleme feststellen können.

Ich bin über SSH mit meinem Benutzer auf dem Ubuntu Server angemeldet und habe auch die Möglichkeit mit dem Befehl `sudo` und einem Passwort die root Rechte zu erhalten. Das ist sehr wichtig für die weiteren Schritte.

Man kann die Zertifikate natürlich auch woanders auf dem Server speichern, ich habe sie allerdings alle im Verzeichnis `/root/certs` abgelegt.

Dafür erstellen wir zuerst einmal unser `/certs` Verzeichnis mit dem Befehl `sudo mkdir /root/certs`. Dort speichern wir nachher all unsere Zertifikate, Schlüssel und weitere benötigte Dateien für unsere Zertifizierungsstelle ab.

Mit dem folgenden Befehl erstellen wir ein RSA-Schlüsselpaar und sichern dieses in einer Datei. Dabei wird ein 2048-Bit RSA-Schlüsselpaar erstellt, welches mit einem Passwort und Triple DES (DES3) verschlüsselt wird. Dieses selbstgewählte Passwort sollten wir unbedingt sicher aufbewahren und am besten in einem Passwortmanager speichern.

```
sudo openssl genrsa -des3 -out /root/certs/myCA.key 2048
```

Eine kurze Erklärung zu diesem Befehl: Mit **openssl** rufen wir das Hauptprogramm zum Erstellen unserer Schlüssel und Zertifikate auf. Mit **genrsa** bestimmen wir, dass ein RSA-Schlüsselpaar generiert werden soll.

Die Verschlüsselung mit einem Passwort wird mit **-des3** definiert. Die Ausgabe benennen wir mit **-out /root/certs/myCA.key** und **2048** gibt die Länge des Schlüssels in Bits an. Wir könnten beispielsweise mit **4096** auch einen längeren Schlüssel erstellen.

Mit dem Befehl `sudo ls -l /root/certs` sollten wir die nun gespeicherte **myCA.key** Datei angezeigt bekommen. Das „CA“ steht hierbei für „Certificate authority“. Mit diesem Schlüssel werden wir auch alle weiteren Zertifikate für die lokalen Server erstellen, daher sollte dieser Schlüssel schon verschlüsselt sein.

Wir werden bei jeder Verwendung dieses Schlüssels nach dem Passwort gefragt und das aber nur bei der Erstellung eines neuen Zertifikates und nicht wenn die Webseite über HTTPS aufgerufen wird. Ich habe selbstverständlich ein kompliziertes Passwort verwendet und dies in meinem Passwortmanager abgespeichert.

## Konfigurationsdatei für das Root-Zertifikat

Beim Erstellen eines neuen Root SSL-Zertifikates werden bestimmte Parameter abgefragt, die man natürlich direkt während der Erstellung eingeben könnte. Mit dieser Konfigurationsdatei passiert das jedoch automatisch. Ich habe mir dafür eine `root.cnf` Datei erstellt.

```
sudo nano /root/certs/root.cnf
```

Folgenden Inhalt habe ich hinzugefügt:

```
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = x509_ext

[ dn ]
C=PY
ST=Caazapa
L=El Paraiso Verde
O=Sebastian Zehner
OU=Homelab
emailAddress=meine@email.com
CN = pi-server.lan

[ x509_ext ]
basicConstraints = critical, CA:TRUE
```

Diese Datei enthält die Konfigurationseinstellungen für das Zertifikat und Du kannst entsprechend die Felder innerhalb [ dn ] für deine Umgebung anpassen.

- (C) Land
- (ST) Bundesland
- (L) Ort
- (O) Organisation
- (OU) Abteilung der Organisation
- (CN) Server Name

Ich habe Pi-Hole bei mir als DHCP Server konfiguriert und dort als Domainname **lan** eingetragen. Der Raspberry Pi Server hat den Hostnamen **pi-server** und daher habe ich bei **CN** die Domain **pi-server.lan** eingetragen. Mein lokaler Webserver lässt sich auch mit **pi-server.lan** im Browser aufrufen.

Wichtig ist außerdem die Erweiterung **x509_ext** damit unser Zertifikat auch bei Smartphones mit Android funktioniert. Ab Android Version 10 ist die Kennzeichnung **CA:TRUE** erforderlich, ansonsten lässt sich das Zertifikat nicht auf den Endgeräten importieren. Es wird damit auch die Zertifikat Version 3 erstellt und nicht mehr die Version 1.

Aus diesem Grund habe ich mir nochmal ein neues Root-Zertifikat erstellt und überall ausgetauscht. Ich hatte leider erst hinterher bemerkt, dass mir Android hier Probleme bereitet und einen Tag lang nach einer Lösung gesucht. Diese Dokumentation ist bereits aktualisiert und funktioniert.

## Erstellen des Root-Zertifikates

Wir können jetzt mit folgendem Befehl das Root-Zertifikat erstellen:

```
sudo openssl req -x509 -new -nodes -key /root/certs/myCA.key -sha256 -days 825 -out /root/certs/myCAnew.pem -config /root/certs/root.cnf
```

Dabei wird das Passwort abgefragt, welches wir zuvor bestimmt und in einem Passwortmanager abgespeichert haben. Wir sollten nun mit dem Befehl `sudo ls -l /root/certs` auch die gespeicherte myCAnew.pem Datei angezeigt bekommen.

Eine kurze Erklärung zu diesem Befehl: Mit **openssl req** rufen wir die Erstellung einer Zertifikatsanforderung auf und mit **-x509** erstellen wir ein selbst signiertes Zertifikat, anstatt eine Zertifikatsanforderung zu erstellen.

Wir möchten ein neues Zertifikat erstellen, daher geben wir **-new** an. Mit **-nodes** verhindern wir die Verschlüsselung des Root-Zertifikates, damit wir nicht bei jeder Benutzung ein Passwort eingeben müssen.

Unseren privaten Schlüssel, welchen wir zuvor erstellt haben, geben wir mit **-key /root/certs/myCA.key** an. Mit **-sha256** definieren wir den Hash-Algorithmus, welcher zur Signierung des Zertifikates verwendet wird. Die Gültigkeitsdauer des Zertifikates geben wir mit **-days 825** in Tagen an.

Jeder kann selbst entscheiden, wie lange so ein Zertifikat gültig sein soll und wann man es wieder erneuern möchte. Für iOS Geräte sind diese 825 Tage glaube ich das Maximum, damit das Zertifikat auch vom System angenommen wird. Den Pfad um das Zertifikat zu speichern geben wir mit **-out /root/certs/myCAnew.pem** an und verwenden unsere zuvor erstellte Konfigurationsdatei mit **-config /root/certs/root.cnf**.

## SSL Zertifikat für den Server

Wir haben vorhin ein Root-Zertifikat erstellt, mit dem wir jetzt die SSL Zertifikate für unsere lokalen Server generieren können. Zuvor wird allerdings noch eine „Certificate Signing Request“ Datei benötigt, die wir jetzt im nächsten Schritt erstellen werden.

Normalerweise wird auf den Servern auch ein privater Schlüssel erstellt und zusammen mit den Konfigurationsdaten diese **.csr** Datei erstellt, welche danach an die Zertifizierungsstelle gesendet werden kann. Der Grund für diesen Vorgang besteht darin, dass keine Schlüssel durch das Internet versendet werden.

Da wir uns in unserem eigenen lokalen Netzwerk befinden, ist das für uns nicht so wichtig und wir erstellen auch diese Datei auf unserem Raspberry Pi. Momentan ist die Zertifizierungsstelle und der Server sowieso ein und derselbe Raspberry Pi und alles passiert lokal.

## Privaten Schlüssels für den Server

Wir möchten weiterhin Ordnung in unserem `/root/certs` - Verzeichnis halten und benennen daher die zukünftigen Zertifikatsdateien nach dem entsprechenden [ CN ] Servernamen. In unserem Beispiel wird die folgende Datei daher `pi-server.lan.key` heißen. Mit folgendem Befehl generieren wir den privaten Schlüssel für unseren Server:

```
sudo openssl genrsa -out /root/certs/pi-server.lan.key 2048
```

Der Befehl ist im Prinzip der gleiche wie auch bei unserem zuvor erstellten privaten Schlüssel für das Root-Zertifikat, jedoch diesmal ohne **-des3** für die Tripple DES Verschlüsselung mit einem Passwort.

## Konfigurationsdatei für den Webserver

Wir erstellen wieder eine Konfigurationsdatei, um die nachher abgefragten Parameter direkt in einer Datei zu definieren. In meinem Fall, da gleicher Server, auch mit dem gleichen Servernamen. Wir benutzen folgenden Befehl für die **client.cnf** Datei:

```
sudo nano /root/certs/client.cnf
```

Der Inhalt dann entsprechend wie folgt:

```
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
C=PY
ST=Caazapa
L=El Paraiso Verde
O=Sebastian Zehner
OU=Homelab
emailAddress=meine@email.com
CN = pi-server.lan
```

## Certificate Signing Request Datei (.csr)

Wir haben jetzt alles zusammen, um die Request Datei erstellen zu können. Wir nutzen für unsere Ordnung die selbe Namensgebung und erzeugen mit folgendem Befehl die Certificate Signing Request Datei:

```
sudo openssl req -new -key /root/certs/pi-server.lan.key -out /root/certs/pi-server.lan.csr -config /root/certs/client.cnf
```

Eine kurze Erklärung zu diesem Befehl: Mit **openssl req -new** erstellen wir eine neue Zertifikatsignaturanforderung und mit **-key /root/certs/pi-server.lan.key** geben wir den Namen und den Pfad des privaten Schlüssels an, welchen wir für die Zertifikatsignaturanforderung verwenden möchten.

Den Namen und Pfad der zu erstellenden Zertifikatsignaturanforderung geben wir mit **-out /root/certs/pi-server.lan.csr** an. Unsere Konfigurationsdatei geben wir mit **-config /root/certs/client.cnf** an.

Wir haben jetzt fast alles geschafft, um ein SSL Zertifikat für den Webserver zu erstellen und können nun zum letzten Schritt übergehen.

## SSL Zertifikat für unseren Webserver

Um nun endlich unser lang ersehntes SSL Zertifikat für den Webserver erstellen zu können, brauchen wir vorher allerdings noch eine **.ext** Datei, welche die Einstellungen und alternativen DNS bzw. IP Adressen enthält.

### Konfigurationsdatei zum Erstellen des Webserver Zertifikats

Wir erstellen die Datei mit folgendem Befehl:

```
sudo nano /root/certs/pi-server.lan.ext
```

Folgenden Inhalt fügen wir dieser Datei hinzu:

```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = pi-server.lan
DNS.2 = pi.hole
IP.1 = 192.168.7.20
```

Mit dieser Konfigurationsdatei definieren wir die Eigenschaften, welche für unser Zertifikat verwendet werden. Eine kurze Erklärung zu dem Inhalt dieser Datei:

Mit **authorityKeyIdentifier** definieren wir einmal die **keyid**, welche sich auf den Identifier des öffentlichen Schlüssels im Zertifikat bezieht und automatisch aus dem öffentlichen Schlüssel generiert wird. Zusätzlich definieren wir den **issuer**, welcher sich auf den Aussteller des Zertifikats bezieht. Damit ist die Zertifizierungsstelle (CA) gemeint, welche das Zertifikat signiert hat.

Bei **basicConstraints** legen wir mit **CA:FALSE** fest, dass dieses Zertifikat nicht als CA-Zertifikat verwendet werden kann. Es können damit also keine anderen SSL-Zertifikate oder Zertifikatssperrlisten signiert werden.

Mit **keyUsage** definieren wir die Verwendungszwecke des Schlüssels. In unserem Fall ist der Schlüssel für digitale Signaturen, Nachweisbarkeit, Schlüsselverschlüsselung und Datenverschlüsselung vorgesehen.

Mit **subjectAltName** definieren wir die alternativen Namen für die Referenz des Zertifikats. In unserem Fall soll das Zertifikat für mehrere Domains beziehungsweise IP Adressen gültig sein, welche wir unter [ alt_names ] auflisten.

Dabei ist es wichtig, dass auch der [ CN ] des Servers mit aufgeführt wird, damit es später bei der Benutzung keine Probleme gibt.

Da wir jetzt eine Konfigurationsdatei mit den Eigenschaften für das Zertifikat erstellt haben, können wir nun das eigentliche SSL Zertifikats für unseren Webserver erstellen. Dazu geben wir folgenden Befehl ein:

```
sudo openssl x509 -req -in /root/certs/pi-server.lan.csr -CA /root/certs/myCAnew.pem -CAkey /root/certs/myCA.key -CAcreateserial -out /root/certs/pi-server.lan.crt -days 825 -sha256 -extfile /root/certs/pi-server.lan.ext
```

Bei der Erstellung des Zertifikats wird natürlich wieder das Verschlüsselungspasswort des myCA.key abgefragt, welches wir in unserem Passwortmanager gespeichert haben.

Eine kurze Erklärung zu diesem Befehl: Wir verwenden **openssl x509** um X.509-Zertifikate zu verwalten und mit **-req** sagen wir, dass wir einen Certificate Signing Request (CSR) verarbeiten möchten. Diese Datei geben wir mit Pfad und Namen wie folgt an **-in /root/certs/pi-server.lan.csr**, genauso mit dem CA-Zertifikat **-CA /root/certs/myCAnew.pem** und dem privaten Schlüssel **-CAkey /root/certs/myCA.key**.

Damit für dieses Zertifikat auch eine Seriennummer erstellt wird, geben wir **-CAcreateserial** mit an. Den Pfad und Namen der Datei, in die das Zertifikat geschrieben werden soll geben wir mit **-out /root/certs/pi-server.lan.crt** an.

Die Gültigkeitsdauer in Tagen wird mit **-days 825** und der Hash-Algorithmus mit **-sha256** angegeben. Die Datei mit den enthaltenen Erweiterungen geben wir mit **-extfile /root/certs/pi-server.lan.ext** an, damit diese mit ins Zertifikat aufgenommen werden.

Mit dem Befehl `sudo ls -l /root/certs` sollten wir nun alle bereits erzeugten Dateien angezeigt bekommen. Wir haben jetzt also ein Zertifikat für unseren Server erstellt, welches wir nun bei unserem Webserver einbinden werden.

Das **myCAnew.pem** Root-Zertifikat müssen wir auf den Endgeräten installieren, mit denen wir über den Browser die Webseite des Webservers aufrufen möchten. In meinem ersten Fall ist das ein Mac Studio mit MacOS und wir müssen dieses Root-Zertifikat in den Schlüsselbund mit aufnehmen, damit der Browser das Zertifikat des Servers als vertrauenswürdig identifizieren kann.

## Kombinieren von SSL-Zertifikat und Schlüssel

Bei unserem Webserver auf dem Pi-Hole läuft wird der Lighttpd Server verwendet und da wird eine kombinierte **.pem** Datei benötigt, die aus dem Zertifikat und privaten Schlüssel besteht. Dafür kombinieren wir einmal die beiden Dateien mit folgendem Befehl:

```
sudo bash -c 'cat /root/certs/pi-server.lan.crt /root/certs/pi-server.lan.key > /root/certs/pi-server.lan.combined.pem'
```

## Vorbereitungen für die Lighttpd Installation

Wie bereits erwähnt läuft bei mir Pi-Hole standardmäßig mit der Lighttpd Installation und dort müssen wir Vorbereitungen treffen, damit überhaupt HTTPS funktionieren kann.

Wir aktivieren zuerst die SSL Unterstützung, indem wir auf dem Raspberry Pi eine **external.conf** Datei mit folgendem Befehl erstellen:

```
sudo nano /etc/lighttpd/conf-available/external.conf
```

Der Inhalt dieser ext. Konfigurationsdatei sieht bei mir wie folgt aus:

```
$SERVER["socket"] == ":443" {
  ssl.engine = "enable"
  ssl.pemfile = "/etc/ssl/private/pi-server.lan.combined.pem"
}

$SERVER["socket"] == ":80" {
        $HTTP["host"] =~ "(.*)" {
                url.redirect = ( "^/(.*)" => "https://%1/$1" )
        }
}
```

Hier wird zuerst die SSL Engine mit dem Port 443 eingeschaltet und der Pfad zum SSL Zertifikat angegeben. Danach wird zusätzlich eine Weiterleitung eingerichtet, damit alle HTTP Anfragen auf HTTPS umgeleitet werden und somit immer eine sichere Verbindung mit dem SSL Zertifikat aufgebaut wird.

Als nächstes kopieren wir die zuvor zusammengesetzte Datei mit dem Zertifikat und privaten Schlüssel mit folgendem Befehl an die richtige Stelle, damit der Lighttpd oder auch Apache2 Server Zugriff darauf haben:

```
sudo cp /root/certs/pi-server.lan.combined.pem /etc/ssl/private/pi-server.lan.combined.pem
```

Ich habe anschließend noch die Gruppenzugehörigkeit **ssl-cert** für die Datei **pi-server.lan.combined.pem** mit folgendem Befehl bestimmt:

```
sudo chgrp ssl-cert /etc/ssl/private/pi-server.lan.combined.pem
```

Die Leseberechtigung für **Others** habe ich mit folgendem Befehl entfernt:

```
sudo chmod o-r /etc/ssl/private/pi-server.lan.combined.pem
```

Die **external.conf** wird standardmäßig mit der Hauptkonfiguration von Lighttpd geladen und hat den Vorteil, dass bei Updates der Hauptkonfiguration unsere Konfiguration erhalten bleibt.

Zum Abschluss müssen wir noch einen Link erstellen, da Lighttpd in dem Verzeichnis `/etc/lighttpd/conf-enabled` nach aktiven Konfiguration schaut und dies machen wir mit folgendem Befehl:

```
sudo ln -s /etc/lighttpd/conf-available/external.conf /etc/lighttpd/conf-enabled/external.conf
```

## Überprüfen der Lighttpd Konfigurationen

Unsere Konfiguration können wir nun mit folgendem Befehl überprüfen:

```
lighttpd -t -f /etc/lighttpd/lighttpd.conf
```

Möglicherweise wird hier angezeigt, dass der „mod_openssl“ fehlt, andernfalls heißt es **Syntax OK**. Sollte der „mod_openssl“ fehlen, können wir diesen ganz einfach mit folgendem Befehl installieren:

```
sudo apt-get install lighttpd-mod-openssl
```

Jetzt müssen wir noch die Lighttpd Konfiguration wie folgt erweitern:

```
sudo nano /etc/lighttpd/lighttpd.conf
```

Die Server Module werden ganz am Anfang geladen und das soll auch so sein. Ich habe an erster Stelle den „mod_openssl“ hinzugefügt. Das Ergebnis sieht jetzt wie folgt aus:

```
„server.modules = (
    "mod_openssl",  « diese Zeile kam hinzu
    "mod_indexfile",
    "mod_access",
    "mod_alias",
     "mod_redirect",
)
```

Nach dem Speichern der Konfiguration muss der Lighttpd Server einmal neu gestartet werden und erst danach sind die ganzen Änderungen aktiv:

```
sudo service lighttpd restart
```

## Vorbereitungen für die Apache2 Installation

Hier ist es ähnlich und wir müssen auch einen `mod_ssl` aktivieren. Wir können dieses Modul mit folgendem Befehl aktivieren:

```
sudo a2enmod ssl
```

Es gibt bei der Apache2 Installation eine default HTTPS Konfiguration unter `/etc/apache2/sites-available/default-ssl.conf`, welche wir uns einmal mit folgendem Befehl kopieren können:

```
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/pi-server.lan-ssl.conf
```

An der entsprechenden Stelle gebe ich meinen Pfad zum Zertifikat für diesen Webserver an. Ich nutze das gleiche Zertifikat als Kombination mit dem privaten Schlüssel wie auch beim Lighttpd Server:

```
SSLCertificateFile      /etc/ssl/private/pi-server.lan.combined.pem
```

Außerdem habe ich noch den Standardport verändert, weil der Port 443 für HTTPS bereits von Lighttpd verwendet wird und daher soll Apache2 den Port 8443 für HTTPS verwenden, damit es da keine Konflikte gibt. Den DocumentRoot habe ich auch entsprechend angepasst aber das ist abhängig von deiner Server Konfiguration und wo die ganzen Dateien für die Webseite liegen.

```
<VirtualHost *:8443>
DocumentRoot /var/www/html/intranet
```

Mit folgendem Befehl konfigurieren wir Apache2 für HTTPS mit unserer Konfigurationsdatei:

```
sudo a2ensite pi-server.lan.combined.conf
```

Damit diese Änderungen auch übernommen und aktiviert werden, starten wir den Apache2 Server mit folgendem Befehl neu:

```
sudo systemctl restart apache2.service
```

Jetzt haben wir auch den Apache2 Webserver erfolgreich für HTTPS konfiguriert und wir sollten uns nun um die Endgeräte kümmern, die den sicheren Zugang zum Webserver bekommen.

## Importieren des Root-Zertifikats in MacOS

Zuerst müssen wir das Root-Zertifikat von der Zertifizierungsstelle, also dem Raspberry Pi, auf meinen lokalen Mac kopieren.

Da ich meine Zertifikate alle in **/root/certs** gespeichert habe und ich dort mit meinem Benutzerkonto über `ssh` ohne `sudo` keinen Zugriff habe, muss ich das Zertifikat vorher noch auf dem Raspberry Pi in mein **home** Verzeichnis kopieren.

Dafür benutzen wir folgenden Befehl, da ich mich bereits in meinem **home** Verzeichnis befinde:

```
sudo cp /root/certs/myCAnew.pem .
```

Jetzt können wir das System wechseln. Da ich MacOS habe nutze ich für die Übertragung auch dort das Terminal und bleibe ebenfalls in meinem **home** Verzeichnis. Mit dem folgenden Befehl kopieren wir die **myCAnew.pem** Datei vom Raspberry Pi auf den Mac Studio:

```
rsync -avzh user@pi-server.lan:myCAnew.pem .
```

Anschließend finden wir unser Root-Zertifikat im **home** Verzeichnis auf dem Mac Studio und können dieses in den Schlüsselbund mit aufnehmen. Dazu öffnen wir über den Finder die **myCAnew.pem** Datei mit dem Schlüsselbund und fügen sie dem System hinzu.

Jetzt müssen wir im Schlüsselbund nur noch mit einem Doppelklick auf das Zertifikat klicken. In meinem Fall heißt das **pi-server.lan** und es öffnet sich ein neues Fenster mit den ganzen Informationen zu diesem Zertifikat.

Oben öffnen wir den Reiter Vertrauen und wählen **bei Verwendung dieses Zertifikates** „Immer vertrauen“ aus. Wir müssen noch einmal das Passwort vom MacOS System eingeben und die Einstellungen werden übernommen.

Unser erstes Endgerät ist nun fertig konfiguriert und sollte das Zertifikat von unserem Webserver als vertrauenswürdig und sicher einstufen.

Bei jedem Endgerät und Betriebssystem kann die Einbindung eines Root-Zertifikates etwas anders ablaufen. So hat es jedenfalls bei meinem Mac Studio mit MacOS 14.5 einwandfrei funktioniert.

## Importieren des Root-Zertifikats in Windows

Bei Windows sind etwas mehr Schritte erforderlich, um das Root-Zertifikat zu installieren. Die Verwaltung erfolgt über die Microsoft Management Konsole, welche wir am einfachsten mit **Windows + R** und danach mit der Eingabe **mmc** öffnen können.

Man muss sich dort die Umgebung auch erst zurecht basteln. Dazu klicken wir im Menü auf Datei und **Snap-In hinzufügen**, um auf der linken Seite die Zertifikate auszuwählen und mit **Hinzufügen** auf die rechte Seite zu den ausgewählten Snap-Ins zu verschieben. Wir wählen einmal **Computerkonto** aus und anschließend **Lokalen Computer**, danach auf **Fertig stellen** und mit **OK** bestätigen.

Links unterhalb dem Konsolenstamm wird uns nun **Zertifikate (Lokaler Computer)** angezeigt und darunter finden wir den Ordner für **Vertrauenswürdige Stammzertifizierungsstellen**. Dort klicken wir mit der rechten Maustaste drauf und wählen im Menü **Alle Aufgaben » Importieren** aus.

Ein Assistent wird gestartet und wir klicken einmal auf **Weiter** und anschließend auf **Durchsuchen**, um unser Root-Zertifikat (myCAnew.pem) auszuwählen. Danach klicken wir auf **Weiter** und lassen den Zertifikatsspeicher für die **Vertrauenswürdige Stammzertifizierungsstellen** bestehen und klicken wieder auf **Weiter**.

Wir bekommen nochmals eine Übersicht angezeigt und können den Import mit **Fertig stellen** abschließen. Das Root-Zertifikat ist nun erfolgreich importiert worden und wir können unseren Webserver über einen Browser aufrufen und uns wird die Verbindung als sicher angezeigt und das Zertifikat ist gültig.

## Importieren des Root-Zertifikats in Android

Der Import in Android hat mich am meisten Zeit und Nerven gekostet. Wie bereits beschrieben, gab es bei Android ab Version 10 eine Änderung im System und die Root-Zertifikate werden ohne die Kennzeichnung **CA:TRUE** nicht mehr importiert. Wir haben mit unserer Dokumentation jedoch die erforderlichen Voraussetzungen geschaffen und erfüllt.

Wir können unser Root-Zertifikat **myCAnew.pem** beispielsweise per E-Mail zusenden und darüber lokal in Downloads abspeichern. Anschließend über die System Sicherheitseinstellungen importieren und das Zertifikat kann genutzt werden.

Dieser [Link](https://stackoverflow.com/questions/57565665/one-self-signed-cert-to-rule-them-all-chrome-android-and-ios/57684211#57684211) hat mir letztendlich geholfen eine Lösung zu finden. Der dort beschriebene sehr einfache Vorgang funktioniert auch, war mir letztendlich dann aber doch etwas zu unsicher und ich habe die aufwendigere Konfiguration, wie hier in meinem Blogartikel beschrieben beibehalten.

## Importieren des Root-Zertifikats in iPadOS

Beim Apple iPad kann das Zertifikat **myCAnew.pem** in iCloud gespeichert und von dort aufgerufen werden. Es wird dadurch ein Profil geladen, welches in den Einstellung direkt zu sehen sein wird.

Dort können wir "Profil geladen" auswählen und es werden uns die Informationen zum Zertifikat angezeigt. Sofern wir sicher sind, dass es sich dabei um unser Root-Zertifikat handelt, können wir oben rechts auf **Installieren** tippen.

Es wird das iPad Passwort abgefragt, um ein Root-Zertifikat installieren zu können. Sobald wir dieses eingegeben haben kommt eine Warnung, dass durch die Installation dieses Zertifikat zur "Liste der vertrauenswürdigen Zertifikate" auf deinem iPad hinzugefügt wird.

Das wollen wir auch und tippen nochmal auf **Installieren**. Danach gleich nochmal auf Profil **Installieren**.

Nun wurde das Zertifikat erfolgreich installiert und es erscheint ein grüner Haken bei **Überprüft** :white_check_mark:

Wir können anschließend auf **Fertig** tippen und finden das Zertifikat nun als **Konfigurationsprofil** unter "Allgemein" und "VPN und Geräteverwaltung" in den iPadOS Einstellungen. Dort könnte man das Root-Zertifikat auch jederzeit wieder entfernen.

Nun müssen wir in den Einstellungen auf **Allgemein** >> **Info** >> **Zertifikatsvertrauenseinstellungen** und aktivieren **volles Vertrauen für Root-Zertifikate** indem wir den Schalter neben unserem **pi-server.lan** umlegen. Es kommt nochmals ein Warnhinweis und wir bestätigen diesen mit **Weiter**.

Damit haben wir unser Root-Zertifikat erfolgreich in iPadOS 17.5.1 installiert und bekommen jetzt eine sichere Verbindung wenn wir über den Browser unseren lokalen Webserver aufrufen.

## Abschluss und Erfolg

Jetzt haben wir alle erforderlichen Zertifikate installiert und sollten mit den entsprechenden Domains oder IP Adressen unseren Webserver erreichen können und keine Warnmeldung mehr erhalten.

Ich kann meine Webseiten entsprechend wie folgt aufrufen:

`https://pi.hole/` für unser Pi-Hole Webinterface.

`https://pi-server.lan:8443` für unser Intranet.

Man hätte natürlich auch beides über einen Webserver laufen lassen können aber ich hatte mein Intranet schon mit Apache2 in Betrieb und die Pi-Hole Installation hat automatisch den Lighttpd Server zusammen mit php installiert.

Für mein Intranet nutze ich überhaupt kein php. Wahrscheinlich deinstalliere ich irgendwann den Apache2 wieder und lass alles über den Lighttpd Server laufen.

Ich hoffe dir hilft dieser Blogartikel bei deinen Projekten weiter und für mich dient er als Dokumentation, falls ich irgendwann nochmal drauf zurückgreifen muss, weil ich etwas vergessen habe.

Man weiß ja nie :sweat_smile:

Vielleicht fällt dir auch etwas auf, was ich hätte besser machen können oder was ich aus Sicherheitsgründen vielleicht noch verändern sollte?

Lass mich das bitte gerne in den Kommentaren wissen. Vielen Dank!

Liebe Grüße
Sebastian

## Ressourcen

Folgende Links haben mir für meine Zertifizierungsstelle geholfen:

- Pi-Hole mit Lighttpd HTTPS fähig machen - [Link](https://mojo.lichtfreibeuter.de/pihole-mit-lighttpd-server-ssl-https-faehig-machen/)
- SSL Zertifikate selbst signieren - [Link](https://mojo.lichtfreibeuter.de/ssl-zertifikate-selbst-signieren-root-und-client-zertifikate-erstellen/)
- Apache2 Module verwenden - [Link](https://ubuntu.com/server/docs/how-to-use-apache2-modules)
- MacOS Zertifikate installieren - [Link](https://flaviocopes.com/macos-install-ssl-local/)
- Android Problematik lösen - [Link](https://stackoverflow.com/questions/57565665/one-self-signed-cert-to-rule-them-all-chrome-android-and-ios/57684211#57684211)
- Root Zertifizierungsstelle im LAN - [Link](https://www.markjunghanns.de/de_DE/index.php/2016/08/18/eine-eigene-root-zertifizierungsstelle-fuer-die-nutzung-im-lan-erstellen/)

{{< chat how-do-we-sign-our-ssl-certificates-with-openssl-for-local-web-services >}}
