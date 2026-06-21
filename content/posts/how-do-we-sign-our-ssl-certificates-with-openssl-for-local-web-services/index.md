+++
title = 'How we sign our SSL certificates with OpenSSL for local web services'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'In this blog post, I document how we create self-signed SSL certificates and use them securely in the local network. A local web server is running on an older Raspberry Pi in my Homelab.'
date = 2024-07-31T20:53:58-04:00
lastmod = 2024-07-31T20:53:58-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['OpenSSL', 'HTTPS', 'Certificates', 'LAN']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true
+++

I am documenting how we can create self-signed SSL certificates and use them securely on the local network. I have installed a local web server in my Homelab on an older Raspberry Pi and would like these websites to display a secure connection via HTTPS in the browser.

This was configured once with Apache2 but also with a Lighttpd server, where my Pi-Hole installation runs. The Pi-Hole Admin Dashboard as well as my intranet website on Apache2 are now securely accessible via HTTPS. How we get all this configured is described in the following documentation.

We start with the creation of SSL certificates and use them to secure our web service. The main reason I looked into this in the first place was the fact that my browser was displaying "Not secure" with an exclamation mark and I didn't like that.

We fixed this today and then, after all the necessary configurations, we have a secure connection with the browser to the web server by using a valid and self-signed certificate.

## What do we need for the SSL certificates?

That depends on our server environment. I use a Raspberry Pi with Ubuntu 24.04 LTS and have set up access via SSH using the terminal on my Mac Studio. SSH access is important and we need OpenSSL installed on the server.

We use the `openssl version` command to check whether the OpenSSL application is already installed on our server and if not, this can be easily done with the following two commands. By the way, I am using OpenSSL version 3.0.13 from January 30, 2024.

```
sudo apt-get update
sudo apt-get install openssl
```

We have thus created the necessary requirements to start with our own certificates.

## Our own SSL certification authority for root certificates (root CA)

We not only need to install a certificate on our server, we also need to integrate the SSL root certificate on our client user computers in order to be able to check the trustworthiness of the server certificate and only then will a secure connection be displayed in the browser.

If I only install the certificate on the server, an invalid certificate or an insecure connection is still displayed on the end devices that want to access the web server via a browser.

In the end, I therefore also have to integrate the SSL root certificate on my Mac Studio so that the connection is displayed as secure and trustworthy. I'll show you exactly how to do that on MacOS at the very end. I'll also show you how to do this on a Windows notebook, an Android smartphone and an Apple iPad with iOS or iPadOS.

I only use one root certificate in my local network and therefore only have to integrate this certificate on the relevant end devices. I use this root certificate to create all other certificates for my servers. For now, however, only one for the web server and the Pi-Hole installation on my Raspberry Pi. Now let's start with the main work. Let's go :rocket:

## Wir erstellen den privaten (Root) Schlüssel

First, we need a private key on our certification authority. In my case, this is also the Raspberry Pi with its Ubuntu Linux installation. Basically, it doesn't matter where we create our keys. I just do it all on the same server and haven't noticed any problems so far.

I am logged on to the Ubuntu server via SSH with my user and also have the option of obtaining root rights with the `sudo` command and a password. This is very important for the next steps.

Of course you can also store the certificates somewhere else on the server, but I have stored them all in the `/root/certs` directory.

To do this, we first create our `/certs` directory with the command `sudo mkdir /root/certs`. We will then save all our certificates, keys and other files required for our certification authority there.

With the following command, we create an RSA key pair and save it in a file. A 2048-bit RSA key pair is created, which is encrypted with a password and Triple DES (DES3). We should keep this self-selected password safe and ideally save it in a password manager.

```
sudo openssl genrsa -des3 -out /root/certs/myCA.key 2048
```

A brief explanation of this command: With **openssl** we call the main program for creating our keys and certificates. With **genrsa** we specify that an RSA key pair is to be generated.

Encryption with a password is defined with **-des3**. We name the output with **-out /root/certs/myCA.key** and **2048** specifies the length of the key in bits. For example, we could also create a longer key with **4096**.

With the command `sudo ls -l /root/certs` we should get the now saved **myCA.key** file displayed. The "CA" stands for "Certificate authority". We will also use this key to create all further certificates for the local servers, so this key should already be encrypted.

We are asked for the password each time this key is used, but only when a new certificate is created and not when the website is accessed via HTTPS. I have of course used a complicated password and saved it in my password manager.

## Configuration file for the root certificate

When creating a new root SSL certificate, certain parameters are requested, which you could of course enter directly during creation. With this configuration file, however, this happens automatically. I have created a `root.cnf` file for this purpose.

```
sudo nano /root/certs/root.cnf
```

I have added the following content:

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

This file contains the configuration settings for the certificate and you can customize the fields within [ dn ] for your environment.

- (C) Country
- (ST) State
- (L) City
- (O) Organization
- (OU) Department of the organization
- (CN) Server Name

I have configured Pi-Hole as a DHCP server and entered **lan** as the domain name. The Raspberry Pi server has the host name **pi-server** and therefore I have entered the domain **pi-server.lan** in **CN**. My local web server can also be called up in the browser with **pi-server.lan**.

The **x509_ext** extension is also important so that our certificate also works on smartphones with Android. From Android version 10, the **CA:TRUE** flag is required, otherwise the certificate cannot be imported onto the end devices. This also creates certificate version 3 and no longer version 1.

For this reason, I created a new root certificate and replaced it everywhere. Unfortunately, I only realized afterwards that Android was causing me problems here and spent a day searching for a solution. This documentation has already been updated and works.

## Creating the root certificate

We can now create the root certificate with the following command:

```
sudo openssl req -x509 -new -nodes -key /root/certs/myCA.key -sha256 -days 825 -out /root/certs/myCAnew.pem -config /root/certs/root.cnf
```

The password that we have previously defined and saved in a password manager is requested. We should now use the command `sudo ls -l /root/certs` to display the saved myCAnew.pem file.

A brief explanation of this command: With **openssl req** we invoke the creation of a certificate request and with **-x509** we create a self-signed certificate instead of creating a certificate request.

We want to create a new certificate, so we specify **-new**. With **-nodes** we prevent the root certificate from being encrypted so that we don't have to enter a password every time we use it.

We specify our private key, which we created previously, with **-key /root/certs/myCA.key**. With **-sha256** we define the hash algorithm which is used to sign the certificate. We specify the validity period of the certificate with **-days 825** in days.

Everyone can decide for themselves how long such a certificate should be valid and when they want to renew it. For iOS devices, I think these 825 days are the maximum so that the certificate is also accepted by the operating system. We specify the path to save the certificate with **-out /root/certs/myCAnew.pem** and use our previously created configuration file with **-config /root/certs/root.cnf**.

## SSL certificate for the server

We created a root certificate earlier, which we can now use to generate the SSL certificates for our local servers. However, a "Certificate Signing Request" file is required first, which we will now create in the next step.

Normally, a private key is also created on the servers and this **.csr** file is created together with the configuration data, which can then be sent to the certification authority. The reason for this process is that no keys are sent via the Internet.

As we are in our own local network, this is not so important for us and we also create this file on our Raspberry Pi. At the moment, the certification authority and the server are one and the same Raspberry Pi anyway and everything happens locally.

## Private key for the server

We want to keep our `/root/certs` directory organized and therefore name the future certificate files after the corresponding [ CN ] server name. In our example, the following file will be named `pi-server.lan.key`. We generate the private key for our server with the following command:

```
sudo openssl genrsa -out /root/certs/pi-server.lan.key 2048
```

The command is basically the same as for our previously created private key for the root certificate, but this time without **-des3** for the Triple DES encryption with a password.

## Configuration file for the web server

We again create a configuration file to define the parameters requested later directly in a file. In my case, since it is the same server, it also has the same server name. We use the following command for the **client.cnf** file:

```
sudo nano /root/certs/client.cnf
```

The content is as follows:

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

## Certificate Signing Request file (.csr)

We now have everything we need to create the request file. We use the same naming convention for our order and create the certificate signing request file with the following command:

```
sudo openssl req -new -key /root/certs/pi-server.lan.key -out /root/certs/pi-server.lan.csr -config /root/certs/client.cnf
```

A brief explanation of this command: With **openssl req -new** we create a new certificate signing request and with **-key /root/certs/pi-server.lan.key** we specify the name and path of the private key we want to use for the certificate signing request.

We specify the name and path of the certificate signing request to be created with **-out /root/certs/pi-server.lan.csr**. We specify our configuration file with **-config /root/certs/client.cnf**.

We have now done almost everything to create an SSL certificate for the web server and can now move on to the last step.

## SSL certificate for our web server

To finally be able to create our long-awaited SSL certificate for the web server, we first need an **.ext** file containing the settings and alternative DNS or IP addresses.

### Configuration file for creating the web server certificate

We create the file with the following command:

```
sudo nano /root/certs/pi-server.lan.ext
```

We add the following content to this file:

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

We use this configuration file to define the properties that are used for our certificate. A brief explanation of the content of this file:

With **authorityKeyIdentifier** we define the **keyid**, which refers to the identifier of the public key in the certificate and is automatically generated from the public key. In addition, we define the **issuer**, which refers to the issuer of the certificate. This refers to the certification authority (CA) that signed the certificate.

For **basicConstraints**, we use **CA:FALSE** to specify that this certificate cannot be used as a CA certificate. This means that no other SSL certificates or certificate revocation lists can be signed with it.

With **keyUsage** we define the intended use of the key. In our case, the key is intended for digitalSignature, nonRepudiation, keyEncipherment and dataEncipherment.

With **subjectAltName** we define the alternative names for the reference of the certificate. In our case, the certificate should be valid for several domains or IP addresses, which we list under [ alt_names ].

It is important that the [ CN ] of the server is also listed so that there are no problems later when using the certificate.

Now that we have created a configuration file with the properties for the certificate, we can create the actual SSL certificate for our web server. To do this, we enter the following command:

```
sudo openssl x509 -req -in /root/certs/pi-server.lan.csr -CA /root/certs/myCAnew.pem -CAkey /root/certs/myCA.key -CAcreateserial -out /root/certs/pi-server.lan.crt -days 825 -sha256 -extfile /root/certs/pi-server.lan.ext
```

When creating the certificate, the encryption password of the myCA.key, which we have saved in our password manager, is of course requested again.

A brief explanation of this command: We use **openssl x509** to manage X.509 certificates and with **-req** we say that we want to process a Certificate Signing Request (CSR). We specify this file with path and name as follows **-in /root/certs/pi-server.lan.csr**, as well as the CA certificate **-CA /root/certs/myCAnew.pem** and the private key **-CAkey /root/certs/myCA.key**.

To ensure that a serial number is also created for this certificate, we specify **-CAcreateserial**. We define the path and name of the file to which the certificate is to be written with **-out /root/certs/pi-server.lan.crt**.

The validity period in days is specified as **-days 825** and the hash algorithm as **-sha256**. We define the file containing the extensions with **-extfile /root/certs/pi-server.lan.ext** so that they are included in the certificate.

With the command `sudo ls -l /root/certs` we should now see all the files that have already been generated. We have now created a certificate for our server, which we will now integrate into our web server.

We need to install the **myCAnew.pem** root certificate on the end devices that we want to use to access the web server's website via the browser. In my first case, this is a Mac Studio with MacOS and we need to include this root certificate in the keychain so that the browser can identify the server's certificate as trustworthy.

## Combining SSL certificate and key

Our web server running Pi-Hole uses the Lighttpd server and requires a combined **.pem** file consisting of the certificate and private key. To do this, we combine the two files once with the following command:

```
sudo bash -c 'cat /root/certs/pi-server.lan.crt /root/certs/pi-server.lan.key > /root/certs/pi-server.lan.combined.pem'
```

## Preparations for the Lighttpd installation

As already mentioned, I run Pi-Hole with the Lighttpd installation by default and we have to make preparations there so that HTTPS can work at all.

We first activate SSL support by creating an **external.conf** file on the Raspberry Pi with the following command:

```
sudo nano /etc/lighttpd/conf-available/external.conf
```

The content of this external configuration file looks as follows:

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

Here, the SSL engine is first activated with port 443 and the path to the SSL certificate is specified. Then a redirect is also set up so that all HTTP requests are redirected to HTTPS and a secure connection is always established with the SSL certificate.

Next, we copy the previously assembled file with the certificate and private key to the correct location using the following command so that the Lighttpd or Apache2 server can access it:

```
sudo cp /root/certs/pi-server.lan.combined.pem /etc/ssl/private/pi-server.lan.combined.pem
```

I then determined the group membership **ssl-cert** for the file **pi-server.lan.combined.pem** with the following command:

```
sudo chgrp ssl-cert /etc/ssl/private/pi-server.lan.combined.pem
```

I have removed the read authorization for **Others** with the following command:

```
sudo chmod o-r /etc/ssl/private/pi-server.lan.combined.pem
```

The **external.conf** is loaded by default with the main configuration of Lighttpd and has the advantage that our configuration is retained when the main configuration is updated.

Finally, we need to create a link, as Lighttpd looks in the `/etc/lighttpd/conf-enabled` directory for active configuration and we do this with the following command:

```
sudo ln -s /etc/lighttpd/conf-available/external.conf /etc/lighttpd/conf-enabled/external.conf
```

## Checking the Lighttpd configurations

We can now check our configuration with the following command:

```
lighttpd -t -f /etc/lighttpd/lighttpd.conf
```

It may be displayed here that the "mod_openssl" is missing, otherwise it says **Syntax OK**. If the "mod_openssl" is missing, we can easily install it with the following command:

```
sudo apt-get install lighttpd-mod-openssl
```

Now we have to extend the Lighttpd configuration as follows:

```
sudo nano /etc/lighttpd/lighttpd.conf
```

The server modules are loaded at the very beginning and that's how it should be. I have added the "mod_openssl" in the first place. The result now looks like this:

```
„server.modules = (
    "mod_openssl",  « this line was added
    "mod_indexfile",
    "mod_access",
    "mod_alias",
     "mod_redirect",
)
```

After saving the configuration, the Lighttpd server must be restarted once and only then are all the changes active:

```
sudo service lighttpd restart
```

## Preparations for the Apache2 installation

Here it is similar and we also need to activate a `mod_ssl`. We can activate this module with the following command:

```
sudo a2enmod ssl
```

The Apache2 installation has a default HTTPS configuration under `/etc/apache2/sites-available/default-ssl.conf`, which we can copy once with the following command:

```
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/pi-server.lan-ssl.conf
```

I enter my path to the certificate for this web server in the appropriate place. I use the same certificate in combination with the private key as for the Lighttpd server:

```
SSLCertificateFile      /etc/ssl/private/pi-server.lan.combined.pem
```

I also changed the default port because port 443 for HTTPS is already used by Lighttpd and therefore Apache2 should use port 8443 for HTTPS so that there are no conflicts. I have also adjusted the DocumentRoot accordingly, but this depends on your server configuration and where all the files for the website are located.

```
<VirtualHost *:8443>
DocumentRoot /var/www/html/intranet
```

With the following command we configure Apache2 for HTTPS with our configuration file:

```
sudo a2ensite pi-server.lan.combined.conf
```

To ensure that these changes are applied and activated, we restart the Apache2 server with the following command:

```
sudo systemctl restart apache2.service
```

Now we have also successfully configured the Apache2 web server for HTTPS and we should now take care of the end devices that get secure access to the web server.

## Importing the root certificate in MacOS

First, we need to copy the root certificate from the certificate authority, i.e. the Raspberry Pi, to my local Mac.

Since I have saved all my certificates in **/root/certs** and I have no access there with my user account via `ssh` without `sudo`, I have to copy the certificate to my **home** directory on the Raspberry Pi first.

To do this, we use the following command, as I am already in my **home** directory:

```
sudo cp /root/certs/myCAnew.pem .
```

Now we can change the system. Since I have MacOS, I also use the terminal for the transfer there and also stay in my **home** directory. With the following command we copy the **myCAnew.pem** file from the Raspberry Pi to the Mac Studio:

```
rsync -avzh user@pi-server.lan:myCAnew.pem .
```

We then find our root certificate in the **home** directory on the Mac Studio and can add it to the keychain. To do this, we open the **myCAnew.pem** file with the keychain via the Finder and add it to the system.

Now we just need to double-click on the certificate in the keychain. In my case, this is **pi-server.lan** and a new window opens with all the information about this certificate.

At the top, we open the Trust tab and select "Always trust" **when using this certificate**. We have to enter the password from the MacOS system again and the settings are applied.

Our first end device is now fully configured and should classify the certificate from our web server as trustworthy and secure.

The integration of a root certificate can be slightly different for each end device and operating system. In any case, it worked perfectly on my Mac Studio with MacOS 14.5.

## Importing the root certificate into Windows

In Windows, a few more steps are required to install the root certificate. It is managed via the Microsoft Management Console, which we can open most easily with **Windows + R** and then by entering **mmc**.

You also have to set up the environment there first. To do this, we click on File and **Add snap-in** in the menu to select the certificates on the left-hand side and move them to the selected snap-ins on the right-hand side with **Add**. We select **Computer account** once and then **Local computer**, then click **Finish** and confirm with **OK**.

We now see **Certificates (local computer)** on the left below the console root and underneath we find the folder for **Trusted root certification authorities**. We right-click on it and select **All tasks > Import** from the menu.

A wizard is started and we click once on **Next** and then on **Browse** to select our root certificate (myCAnew.pem). Then we click on **Next** and leave the certificate store for the **Trusted root certification authorities** and click on **Next** again.

An overview is displayed again and we can complete the import with **Finish**. The root certificate has now been successfully imported and we can access our web server via a browser and the connection is displayed as secure and the certificate is valid.

## Importing the root certificate into Android

The import in Android took me the most time and effort. As already described, there has been a change in the system in Android version 10 and the root certificates are no longer imported without the **CA:TRUE** flag. However, we have created and fulfilled the necessary requirements with our documentation.

For example, we can send our root certificate **myCAnew.pem** by e-mail and save it locally in Downloads. Then import it via the system security settings and the certificate can be used.

This [link](https://stackoverflow.com/questions/57565665/one-self-signed-cert-to-rule-them-all-chrome-android-and-ios/57684211#57684211) ultimately helped me to find a solution. The very simple process described there also works, but in the end I was a bit too insecure and I kept the more complex configuration as described here in my blog post.

## Importing the root certificate into iPadOS

On the Apple iPad, the **myCAnew.pem** certificate can be saved in iCloud and accessed from there. This will load a profile, which will be directly visible in the settings.

There we will be able to select "Profile loaded" and the information about the certificate will be displayed. If we are sure that this is our root certificate, we can tap **Install** in the top right-hand corner.

The iPad password is requested in order to install a root certificate. As soon as we have entered this, a warning appears that the installation will add this certificate to the "list of trusted certificates" on your iPad.

We want this and tap **Install** again. Then tap Profile **Install** again.

The certificate has now been successfully installed and a green checkmark appears next to **Verified** :white_check_mark:

We can then tap on **Done** and now find the certificate as a **Configuration profile** under "General" and "VPN and device management" in the iPadOS settings. You can also remove the root certificate there at any time.

Now we have to go to **General** >> **Info** >> **Certificate trust settings** in the settings and activate **full trust for root certificates** by flipping the switch next to our **pi-server.lan**. Another warning message appears and we confirm this with **Next**.

We have now successfully installed our root certificate in iPadOS 17.5.1 and now have a secure connection when we access our local web server via the browser.

## Closure and success

We have now installed all the required certificates and should be able to reach our web server with the corresponding domains or IP addresses and no longer receive a warning message.

I can access my web pages accordingly as follows:

`https://pi.hole/` for our Pi-Hole web interface.

`https://pi-server.lan:8443` for our intranet.

Of course you could have run both via a single web server, but I was already running my intranet with Apache2 and the Pi-Hole installation automatically installed the Lighttpd server together with php.

I don't use php at all for my intranet. I'll probably uninstall Apache2 again at some point and run everything via the Lighttpd server.

I hope this blog post helps you with your projects and serves as documentation for me in case I need to come back to it at some point because I've forgotten something.

You never know :sweat_smile:

Maybe you notice anything that I could have done better or that I should perhaps change for safety reasons?

Please let me know in the comments. Thank you very much!

Best regards
Sebastian

## Resources

The following links were helpful for my certification authority:

- Making Pi-Hole HTTPS capable with Lighttpd - [Link](https://mojo.lichtfreibeuter.de/pihole-mit-lighttpd-server-ssl-https-faehig-machen/)
- Sign SSL certificates yourself - [Link](https://mojo.lichtfreibeuter.de/ssl-zertifikate-selbst-signieren-root-und-client-zertifikate-erstellen/)
- Use Apache2 modules - [Link](https://ubuntu.com/server/docs/how-to-use-apache2-modules)
- Install MacOS certificates - [Link](https://flaviocopes.com/macos-install-ssl-local/)
- Solving Android problems - [Link](https://stackoverflow.com/questions/57565665/one-self-signed-cert-to-rule-them-all-chrome-android-and-ios/57684211#57684211)
- Root certificate authority in the LAN - [Link](https://www.markjunghanns.de/de_DE/index.php/2016/08/18/eine-eigene-root-zertifizierungsstelle-fuer-die-nutzung-im-lan-erstellen/)

{{< chat how-do-we-sign-our-ssl-certificates-with-openssl-for-local-web-services >}}
