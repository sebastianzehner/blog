+++
title = 'Wie man eine Hugo Webseite hochlädt und veröffentlicht'
summary = 'Im zweiten Teil dieser Serie haben wir einige Inhalte für deine kostenlose Hugo Webseite erstellt und heute wollen wir diese Inhalte hochladen und kostenlos im Internet veröffentlichen.'
date = 2024-12-06T15:00:00-03:00
lastmod = 2024-12-06T15:00:00-03:00

tags = ['Hugo', 'Webseite', 'PaperMod']
categories = ['TechLab']

showComments = true
chatId = "how-to-upload-and-publish-a-hugo-website"
+++

Im [zweiten Teil dieser Serie](/de/posts/how-to-create-content-for-your-free-hugo-website/) haben wir einige Inhalte für deine kostenlose Hugo Webseite erstellt und heute wollen wir diese Inhalte hochladen und kostenlos im Internet veröffentlichen.

## Git vorbereiten und ein GitHub-Repository erstellen

Zunächst müssen wir alle Dateien in ein GitHub-Repository hochladen.

Git muss auf deinem Computer installiert sein. Vergewissere dich, dass du dich im Stammverzeichnis deiner Webseite auf deinem lokalen Rechner befindest, während du das Terminal verwendest und dann den folgenden Befehl eingibst:

```
git init
```

Jetzt wird ein GitHub-Repository initialisiert. Als Nächstes erstellst du eine `.gitmodules` Datei im selben Ordner.

```
touch .gitmodules
```

Das PaperMod Thema sollte ein Submodul im GitHub-Repository sein, also schreibe dies in die Datei `.gitmodules`:

```
[submodule "themes/PaperMod"]
 path = themes/PaperMod
 url = "https://github.com/adityatelange/hugo-PaperMod.git"
```

### Erstelle ein kostenloses Benutzerkonto auf GitHub

Wenn du noch keinen kostenlosen Zugang zu GitHub hast, dann registriere dich jetzt und erstelle dein Repository für deine Webseite. [Link zu GitHub.](https://github.com)

### Erzeuge einen Token für die sichere Authentifizierung

Für die sichere Authentifizierung mit Git auf GitHub wird ein Token benötigt. Erzeuge einen neuen Token auf GitHub.
[Link zu den GitHub Einstellungen.](https://github.com/settings/tokens)

> Note: yourname website
> Expiration: 90 days
> [x] public_repo

Füge anschließend die folgenden Befehle in das Terminal ein:

```
echo "# yourname" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/yourname/blog.git
git push -u origin main
```

Gib deinen Benutzernamen und Token ein, sobald du danach gefragt wirst. Anschließend werden die Dateien in das GitHub-Repository hochgeladen.

### So speicherst und aktualisierst du den Token nach 90 Tagen

Speichere diesen Token in der MacOS Schlüsselbundverwaltung: Klicke auf das Spotlight-Symbol (Lupe) auf der rechten Seite der Menüleiste.

Gib Schlüsselbundverwaltung ein und drücke die Eingabetaste, um die Anwendung zu starten:

- Suche in Schlüsselbundverwaltung nach github.com.
- Suche den Passworteintrag für github.com.
- Bearbeite oder lösche den Eintrag entsprechend.
- Du bist fertig!

> Hinweis: Jetzt kann Git Dateien ohne Fehler auf GitHub hochladen!

Generiere nach 90 Tagen einen neuen Token auf github.com und tausche den alten Token im Schlüsselbund mit dem neu generierten Token aus!

Eventuell zuerst den alten Token aus dem Schlüsselbund löschen und dann einen Push-Befehl mit Benutzername und Passwort/Token ausführen.

Nachdem dieser Befehl erfolgreich war, erstelle einen neuen Eintrag in der MacOS Schlüsselbundverwaltung oder stelle den alten wieder her und ersetze den alten Token durch den neuen Token.

> Hinweis: Dies funktioniert in ähnlicher Weise auch mit anderen Betriebssystemen.

## Wo soll die Webseite bereitgestellt werden?

Erstelle als nächstes ein kostenloses Konto bei Netlify: [https://www.netlify.com/](https://www.netlify.com/)

- Neue Webseite von Git und Verbindung mit GitHub.
- Wähle das Repository auf der Webseite.

Die Bereitstellung erfolgt unter dem Namen yourname im Team yourname aus der Main Branch mit dem Befehl hugo und der Veröffentlichung auf public. Stelle yourname auf Netlify bereit.

Es gab ein Problem mit dem Git submodule, welches mit dem folgenden Befehl behoben wurde. Verwende das Stammverzeichnis der lokalen Webseite im Terminal.

```
git submodule update --remote –init
```

Der Link hat jetzt eine andere Nummer hinter `tree` und bei mir hat es funktioniert.

Nochmals mit Netlify bereitstellen und jetzt sollte es funktionieren. **Die Webseite ist online!**

👉 <https://sebastianzehner.netlify.app>

## Registrierung und Verknüpfung einer Domain mit der Webseite

Ich verwende [Hostinger](https://bit.ly/3W9oyZG) für die Registrierung und Verlängerung von Domains. In den ersten zwei Jahren bietet Hostinger einen Sonderpreis von nur 4,99 USD pro Jahr.

Nach zwei Jahren beträgt der reguläre Preis 15,99 USD pro Jahr für eine **.com**-Domain. Ich habe nur noch eine Domain und möchte sie für meine neue Webseite verwenden.

Wir können [diese Domain in Kryptowährung bezahlen](/de/posts/how-i-paid-for-my-domain-with-cryptocurrency/) für ein, zwei oder drei Jahre. Das gefällt mir und das sind die einzigen Kosten für unsere neue Webseite, denn das Hosting bei Netlifly und GitHub ist kostenlos. Die Software Hugo und das Thema PaperMod sind Open Source und ebenfalls kostenlos.

Auf der Webseite Netlify im Backend richten wir eine eigene Domain ein. Füge eine benutzerdefinierte Domain zu deiner Webseite hinzu und klicke auf **verify** und dann **add domain**. In der Domainverwaltung habe ich einige DNS-Einstellungen erhalten.

```
Point A record to xx.x.xx.x for yourdomain.com
```

Ich änderte die IP-Adresse für meine Domain bei Hostinger in den DNS-Einträgen für den Typ A auf xx.x.xx.x und speicherte diese Einstellungen.

Nach ein paar Minuten hat Netlify diese Änderungen registriert und nun ist meine Webseite unter <http://sebastianzehner.com> erreichbar und <http://www.sebastianzehner.com> leitet auf <http://sebastianzehner.com> um. Dies ist jedoch nicht sicher und wir müssen eine Verschlüsselung einrichten.

## Aktiviere das TLS-Zertifikat: Let's Encrypt

In der Domainverwaltung im Backend von Netlify habe ich die DNS-Konfiguration für das SSL/TLS-Zertifikat überprüft. Ein Klick auf den Button und die DNS-Überprüfung war erfolgreich ✅

Fertig. So unkompliziert. Jetzt ist die Verbindung sicher und die Webseite mit meiner Domain [https://sebastianzehner.com](https://sebastianzehner.com) erreichbar.

In der Zwischenzeit sagt die Domainverwaltung bei Netlify:

- Ihre Webseite hat HTTPS aktiviert ✅

Letzter Schritt zur Konfiguration dieser neuen Domain in der Konfigurationsdatei `hugo.toml`. Füge diese Zeile ein oder benenne sie um:

```
baseURL = 'https://yourdomain.com'
```

Lade diese Änderungen mit einem `git push` ins Internet hoch und wir sind fertig.

Unsere neue sichere und minimalistische Hugo Webseite mit dem PaperMod Thema ist online und Besucher sind herzlich eingeladen, meine coolen Artikel zu lesen 😎

Danke, dass du meinen Blogpost bis hierhin gelesen hast und ich wünsche dir einen schönen Tag und viel Spaß beim Bloggen.

Ich werde in der nächsten Folge dieser Serie mit einem der folgenden Themen weitermachen: Shortcodes, Suchfunktion oder Analytics mit GoatCounter.

Liebe Grüße Sebastian

## Video: Erste Schritte mit Hugo

Dieses tolle Video hilft bei den meisten Punkten. Das Submodul war knifflig und hat mich viel Zeit gekostet, aber jetzt ist alles gut und funktioniert.

{{< youtube hjD9jTi_DQ4 >}}

## Andere nützliche Webseiten und Links

- Umwandeln von yaml zu toml [Link](https://transform.tools/yaml-to-toml)
- Markdown Cheat Sheet [Link](https://www.markdownguide.org/cheat-sheet/)
- Mehrsprachige Menüs [Link](https://gohugo.io/content-management/multilingual/#menus)
- Front matter [Link](https://gohugo.io/content-management/front-matter/)
- PaperMod Features [Link](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)
