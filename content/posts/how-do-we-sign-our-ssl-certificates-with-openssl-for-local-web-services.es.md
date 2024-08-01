+++
title = 'Cómo firmamos nuestros certificados SSL con OpenSSL para servicios web locales'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'En esta entrada de blog, documento cómo creamos certificados SSL autofirmados y los usamos de forma segura en la red local. Un servidor web local se ejecuta en un viejo Raspberry Pi en mi Homelab.'
date = 2024-07-31T20:53:58-04:00
lastmod = 2024-07-31T20:53:58-04:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['OpenSSL', 'HTTPS', 'Certificados', 'LAN']
categories = ['Tech']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true
+++

Estoy documentando cómo podemos crear certificados SSL autofirmados y utilizarlos de forma segura en la red local. He instalado un servidor web local en mi Homelab en un viejo Raspberry Pi y me gustaría que estos sitios web para mostrar una conexión segura a través de HTTPS en el navegador.

Esto se configuró una vez con Apache2 pero también con un servidor Lighttpd, donde se ejecuta mi instalación Pi-Hole. El Pi-Hole Admin Dashboard, así como mi sitio web de la intranet en Apache2 son ahora accesibles de forma segura a través de HTTPS. Cómo configuramos todo esto se describe en la siguiente documentación.

Comenzamos con la creación de certificados SSL y los usamos para asegurar nuestro servicio web. La razón principal por la que investigué esto en primer lugar fue el hecho de que mi navegador mostraba "No seguro" con un signo de exclamación y eso no me gustaba.

Arreglamos esto hoy y entonces, después de todas las configuraciones necesarias, tenemos una conexión segura con el navegador al servidor web usando un certificado válido y autofirmado.

## ¿Qué necesitamos para los certificados SSL?

Eso depende de nuestro entorno de servidor. Yo uso una Raspberry Pi con Ubuntu 24.04 LTS y he configurado el acceso a través de SSH utilizando el terminal en mi Mac Studio. El acceso SSH es importante y necesitamos OpenSSL instalado en el servidor.

Usamos el comando `openssl version` para comprobar si la aplicación OpenSSL ya está instalada en nuestro servidor y si no, se puede hacer fácilmente con los dos comandos siguientes. Por cierto, estoy usando la versión 3.0.13 de OpenSSL del 30 de enero de 2024.

```
sudo apt-get update
sudo apt-get install openssl
```

Así, hemos creado los requisitos necesarios para empezar con nuestros propios certificados.

## Nuestra propia autoridad de certificación SSL para certificados raíz (root CA)

No sólo necesitamos instalar un certificado en nuestro servidor, también necesitamos integrar el certificado raíz SSL en nuestros ordenadores de usuario cliente para poder comprobar la fiabilidad del certificado del servidor y sólo entonces se mostrará una conexión segura en el navegador.

Si sólo instalo el certificado en el servidor, seguirá apareciendo un certificado no válido o una conexión insegura en los dispositivos finales que quieran acceder al servidor web a través de un navegador.

Por lo tanto, al final también tengo que integrar el certificado raíz SSL en mi Mac Studio para que la conexión se muestre como segura y de confianza. Te mostraré exactamente cómo hacerlo en MacOS al final. También te mostraré cómo hacerlo en un portátil Windows, un smartphone Android y un iPad de Apple con iOS o iPadOS.

Sólo utilizo un certificado raíz en mi red local y, por lo tanto, sólo tengo que integrar este certificado en los dispositivos finales pertinentes. Utilizo este certificado raíz para crear todos los demás certificados para mis servidores. Por ahora, sin embargo, sólo uno para el servidor web y la instalación Pi-Hole en mi Raspberry Pi. Ahora empecemos con el trabajo principal. Vamos :rocket:

## Creamos la clave privada (raíz)

En primer lugar, necesitamos una clave privada en nuestra autoridad de certificación. En mi caso, esta es también la Raspberry Pi con su instalación de Ubuntu Linux. Básicamente, no importa dónde creemos nuestras claves. Yo simplemente lo hago todo en el mismo servidor y no he notado ningún problema hasta ahora.

Estoy conectado al servidor Ubuntu a través de SSH con mi usuario y también tengo la opción de obtener derechos de root con el comando `sudo` y una contraseña. Esto es muy importante para los siguientes pasos.

Por supuesto, también puedes almacenar los certificados en otro lugar del servidor, pero yo los he almacenado todos en el directorio `/root/certs`.

Para hacer esto, primero creamos nuestro directorio `/certs` con el comando `sudo mkdir /root/certs`. Allí guardaremos todos nuestros certificados, claves y demás archivos necesarios para nuestra autoridad de certificación.

Con el siguiente comando, creamos un par de claves RSA y lo guardamos en un archivo. Se crea un par de claves RSA de 2048 bits, que se cifra con una contraseña y Triple DES (DES3). Deberíamos mantener esta contraseña auto-seleccionada a salvo e idealmente guardarla en un gestor de contraseñas.

```
sudo openssl genrsa -des3 -out /root/certs/myCA.key 2048
```

Una breve explicación de este comando: Con **openssl** llamamos al programa principal para crear nuestras claves y certificados. Con **genrsa** especificamos que se genere un par de claves RSA.

Con **-des3** definimos el cifrado con contraseña. Nombramos la salida con **-out /root/certs/myCA.key** y **2048** especifica la longitud de la clave en bits. Por ejemplo, también podríamos crear una clave más larga con **4096**.

Con el comando `sudo ls -l /root/certs` deberíamos obtener el archivo ahora guardado **myCA.key**. CA" significa "Autoridad de Certificación". También utilizaremos esta clave para crear todos los demás certificados para los servidores locales, por lo que esta clave ya debería estar cifrada.

Se nos pide la contraseña cada vez que se utiliza esta clave, pero sólo cuando se crea un nuevo certificado y no cuando se accede al sitio web a través de HTTPS. Por supuesto he utilizado una contraseña complicada y la he guardado en mi gestor de contraseñas.

## Archivo de configuración para el certificado raíz

Al crear un nuevo certificado SSL raíz, se solicitan ciertos parámetros que, por supuesto, podría introducir directamente durante la creación. Con este archivo de configuración, sin embargo, esto sucede automáticamente. He creado un archivo `root.cnf` para este propósito.

```
sudo nano /root/certs/root.cnf
```

He añadido el siguiente contenido:

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

Este archivo contiene los ajustes de configuración para el certificado y puede personalizar los campos dentro de [ dn ] para su entorno.

- (C) País
- (ST) Departamento
- (L) Ciudad
- (O) Organización
- (OU) Departamento de la organización
- (CN) Nombre del servidor

He configurado Pi-Hole como servidor DHCP y he introducido **lan** como nombre de dominio. El servidor Raspberry Pi tiene el nombre de host **pi-server** y por lo tanto he introducido el dominio **pi-server.lan** en **CN**. Mi servidor web local también se puede llamar en el navegador con **pi-server.lan**.

La extensión **x509_ext** también es importante para que nuestro certificado también funcione en smartphones con Android. A partir de la versión 10 de Android, se requiere la bandera **CA:TRUE**, de lo contrario el certificado no se puede importar en los dispositivos finales. Esto también crea la versión 3 del certificado y ya no la versión 1.

Por este motivo, creé un nuevo certificado raíz y lo sustituí en todas partes. Por desgracia, sólo me di cuenta después de que Android me estaba causando problemas aquí y pasé un día buscando una solución. Esta documentación ya ha sido actualizada y funciona.

## Creando el certificado raíz

Ahora podemos crear el certificado raíz con el siguiente comando:

```
sudo openssl req -x509 -new -nodes -key /root/certs/myCA.key -sha256 -days 825 -out /root/certs/myCAnew.pem -config /root/certs/root.cnf
```

Se solicita la contraseña que previamente hemos definido y guardado en un gestor de contraseñas. Ahora debemos utilizar el comando `sudo ls -l /root/certs` para mostrar el archivo myCAnew.pem guardado.

Una breve explicación de este comando: Con **openssl req** invocamos la creación de una solicitud de certificado y con **-x509** creamos un certificado autofirmado en lugar de crear una solicitud de certificado.

Queremos crear un nuevo certificado, así que especificamos **-new**. Con **-nodos** evitamos que se cifre el certificado raíz para que no tengamos que introducir una contraseña cada vez que lo utilicemos.

Especificamos nuestra clave privada, que creamos previamente, con **-key /root/certs/myCA.key**. Con **-sha256** definimos el algoritmo hash que se utiliza para firmar el certificado. Con **-days 825** especificamos el periodo de validez del certificado en días.

Cada uno puede decidir por sí mismo cuánto tiempo debe ser válido un certificado de este tipo y cuándo quiere renovarlo. Para dispositivos iOS, creo que estos 825 días son el máximo para que el certificado también sea aceptado por el sistema operativo. Especificamos la ruta para guardar el certificado con **-out /root/certs/myCAnew.pem** y usamos nuestro archivo de configuración creado previamente con **-config /root/certs/root.cnf**.

## Certificado SSL para el servidor

Anteriormente creamos un certificado raíz, que ahora podemos utilizar para generar los certificados SSL para nuestros servidores locales. Sin embargo, primero se necesita un archivo "Certificate Signing Request", que crearemos en el siguiente paso.

Normalmente, también se crea una clave privada en los servidores y este archivo **.csr** se crea junto con los datos de configuración, que luego se pueden enviar a la autoridad de certificación. La razón de este proceso es que no se envían claves a través de Internet.

Como estamos en nuestra propia red local, esto no es tan importante para nosotros y también creamos este archivo en nuestra Raspberry Pi. Por el momento, la autoridad de certificación y el servidor son uno y el mismo Raspberry Pi de todos modos y todo sucede localmente.

## Clave privada para el servidor

Queremos mantener nuestro directorio `/root/certs` organizado y por lo tanto nombrar los futuros archivos de certificado con el nombre del servidor [ CN ] correspondiente. En nuestro ejemplo, el siguiente fichero se llamará `pi-server.lan.key`. Generamos la clave privada para nuestro servidor con el siguiente comando:

```
sudo openssl genrsa -out /root/certs/pi-server.lan.key 2048
```

El comando es básicamente el mismo que para nuestra clave privada creada anteriormente para el certificado raíz, pero esta vez sin **-des3** para el cifrado Triple DES con contraseña.

## Fichero de configuración para el servidor web

Volvemos a crear un fichero de configuración para definir los parámetros solicitados posteriormente directamente en un fichero. En mi caso, al ser el mismo servidor, también tiene el mismo nombre de servidor. Usamos el siguiente comando para el fichero **client.cnf**:

```
sudo nano /root/certs/client.cnf
```

El contenido es el siguiente:

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

## Archivo de solicitud de firma de certificado (.csr)

Ahora tenemos todo lo que necesitamos para crear el archivo de solicitud. Usamos la misma convención de nomenclatura para nuestro pedido y creamos el archivo de solicitud de firma de certificado con el siguiente comando:

```
sudo openssl req -new -key /root/certs/pi-server.lan.key -out /root/certs/pi-server.lan.csr -config /root/certs/client.cnf
```

Una breve explicación de este comando: Con **openssl req -new** creamos una nueva solicitud de firma de certificado y con **-key /root/certs/pi-server.lan.key** especificamos el nombre y la ruta de la clave privada que queremos utilizar para la solicitud de firma de certificado.

Especificamos el nombre y la ruta de la solicitud de firma de certificado que se creará con **-out /root/certs/pi-server.lan.csr**. Especificamos nuestro archivo de configuración con **-config /root/certs/client.cnf**.

Ya hemos hecho casi todo para crear un certificado SSL para el servidor web y ahora podemos pasar al último paso.

## Certificado SSL para nuestro servidor web

Para finalmente poder crear nuestro tan esperado certificado SSL para el servidor web, primero necesitamos un archivo **.ext** que contenga la configuración y las direcciones DNS o IP alternativas.

### Archivo de configuración para crear el certificado del servidor web

Creamos el fichero con el siguiente comando:

```
sudo nano /root/certs/pi-server.lan.ext
```

Añadimos el siguiente contenido a este archivo:

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

Utilizamos este fichero de configuración para definir las propiedades que se utilizan para nuestro certificado. Una breve explicación del contenido de este fichero:

Con **authorityKeyIdentifier** definimos el **keyid**, que hace referencia al identificador de la clave pública del certificado y se genera automáticamente a partir de la clave pública. Además, definimos el **issuer**, que se refiere al emisor del certificado. Se refiere a la autoridad de certificación (CA) que firmó el certificado.

Para **basicConstraints**, utilizamos **CA:FALSE** para especificar que este certificado no puede utilizarse como certificado de CA. Esto significa que no se pueden firmar otros certificados SSL o listas de revocación de certificados con él.

Con **keyUsage** definimos el uso previsto de la clave. En nuestro caso, la clave está destinada a digitalSignature, nonRepudiation, keyEncipherment y dataEncipherment.

Con **subjectAltName** definimos los nombres alternativos para la referencia del certificado. En nuestro caso, el certificado debe ser válido para varios dominios o direcciones IP, que enumeramos en [ alt_names ].

Es importante que también se enumere el [ CN ] del servidor para que no haya problemas más adelante al utilizar el certificado.

Ahora que hemos creado un fichero de configuración con las propiedades del certificado, podemos crear el certificado SSL para nuestro servidor web. Para ello, introducimos el siguiente comando:

```
sudo openssl x509 -req -in /root/certs/pi-server.lan.csr -CA /root/certs/myCAnew.pem -CAkey /root/certs/myCA.key -CAcreateserial -out /root/certs/pi-server.lan.crt -days 825 -sha256 -extfile /root/certs/pi-server.lan.ext
```

Al crear el certificado, se vuelve a solicitar, por supuesto, la contraseña de cifrado de la clave myCA.key, que hemos guardado en nuestro gestor de contraseñas.

Una breve explicación de este comando: Usamos **openssl x509** para gestionar certificados X.509 y con **-req** decimos que queremos procesar una Solicitud de Firma de Certificado (CSR). Especificamos este fichero con ruta y nombre **-in /root/certs/pi-server.lan.csr**, así como el certificado CA **-CA /root/certs/myCAnew.pem** y la clave privada **-CAkey /root/certs/myCA.key**.

Para asegurarnos de que también se crea un número de serie para este certificado, especificamos **-CAcreateserial**. Definimos la ruta y el nombre del archivo en el que se escribirá el certificado con **-out /root/certs/pi-server.lan.crt**.

El periodo de validez en días se especifica como **-days 825** y el algoritmo hash como **-sha256**. Definimos el fichero que contiene las extensiones con **-extfile /root/certs/pi-server.lan.ext** para que se incluyan en el certificado.

Con el comando `sudo ls -l /root/certs` deberíamos ver ahora todos los ficheros que ya se han generado. Ya hemos creado un certificado para nuestro servidor, que ahora integraremos en nuestro servidor web.

Necesitamos instalar el certificado raíz **myCAnew.pem** en los dispositivos finales que queremos utilizar para acceder a la web del servidor web a través del navegador. En mi primer caso, se trata de un Mac Studio con MacOS y necesitamos incluir este certificado raíz en el llavero para que el navegador pueda identificar el certificado del servidor como de confianza.

## Combinando certificado y clave SSL

Nuestro servidor web que ejecuta Pi-Hole utiliza el servidor Lighttpd y requiere un archivo combinado **.pem** compuesto por el certificado y la clave privada. Para ello, combinamos los dos archivos una vez con el siguiente comando:

```
sudo bash -c 'cat /root/certs/pi-server.lan.crt /root/certs/pi-server.lan.key > /root/certs/pi-server.lan.combined.pem'
```

## Preparativos para la instalación de Lighttpd

Como ya se ha mencionado, ejecuto Pi-Hole con la instalación Lighttpd por defecto y tenemos que hacer los preparativos allí para que HTTPS pueda funcionar en absoluto.

Primero activamos el soporte SSL creando un archivo **external.conf** en la Raspberry Pi con el siguiente comando:

```
sudo nano /etc/lighttpd/conf-available/external.conf
```

El contenido de este fichero de configuración externo tiene el siguiente aspecto:

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

Aquí, primero se activa el motor SSL con el puerto 443 y se especifica la ruta al certificado SSL. A continuación, también se configura una redirección para que todas las peticiones HTTP se redirijan a HTTPS y se establezca siempre una conexión segura con el certificado SSL.

A continuación, copiamos el archivo previamente montado con el certificado y la clave privada a la ubicación correcta utilizando el siguiente comando para que el servidor Lighttpd o Apache2 pueda acceder a él:

```
sudo cp /root/certs/pi-server.lan.combined.pem /etc/ssl/private/pi-server.lan.combined.pem
```

Luego determiné la pertenencia al grupo **ssl-cert** para el archivo **pi-server.lan.combined.pem** con el siguiente comando:

```
sudo chgrp ssl-cert /etc/ssl/private/pi-server.lan.combined.pem
```

He eliminado la autorización de lectura para **Otros** con el siguiente comando:

```
sudo chmod o-r /etc/ssl/private/pi-server.lan.combined.pem
```

El **external.conf** se carga por defecto con la configuración principal de Lighttpd y tiene la ventaja de que nuestra configuración se mantiene cuando se actualiza la configuración principal.

Finalmente, necesitamos crear un enlace, ya que Lighttpd busca en el directorio `/etc/lighttpd/conf-enabled` la configuración activa y lo hacemos con el siguiente comando:

```
sudo ln -s /etc/lighttpd/conf-available/external.conf /etc/lighttpd/conf-enabled/external.conf
```

## Comprobando la configuración de Lighttpd

Ahora podemos comprobar nuestra configuración con el siguiente comando:

```
lighttpd -t -f /etc/lighttpd/lighttpd.conf
```

Aquí puede aparecer que falta el "mod_openssl", de lo contrario dice **Sintaxis OK**. Si falta el "mod_openssl", podemos instalarlo fácilmente con el siguiente comando:

```
sudo apt-get install lighttpd-mod-openssl
```

Ahora tenemos que ampliar la configuración de Lighttpd de la siguiente manera:

```
sudo nano /etc/lighttpd/lighttpd.conf
```

Los módulos del servidor se cargan al principio y así es como debe ser. He añadido el "mod_openssl" en primer lugar. El resultado ahora se ve así:

```
„server.modules = (
    "mod_openssl",  « this line was added
    "mod_indexfile",
    "mod_access",
    "mod_alias",
     "mod_redirect",
)
```

Después de guardar la configuración, el servidor Lighttpd debe reiniciarse una vez y sólo entonces se activan todos los cambios:

```
sudo service lighttpd restart
```

## Preparativos para la instalación de Apache2

Aquí es similar y también necesitamos activar un `mod_ssl`. Podemos activar este módulo con el siguiente comando:

```
sudo a2enmod ssl
```

La instalación de Apache2 tiene una configuración HTTPS por defecto bajo `/etc/apache2/sites-available/default-ssl.conf`, que podemos copiar una vez con el siguiente comando:

```
sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/pi-server.lan-ssl.conf
```

Introduzco la ruta al certificado para este servidor web en el lugar apropiado. Utilizo el mismo certificado en combinación con la clave privada que para el servidor Lighttpd:

```
SSLCertificateFile      /etc/ssl/private/pi-server.lan.combined.pem
```

También he cambiado el puerto por defecto porque el puerto 443 para HTTPS ya es usado por Lighttpd y por lo tanto Apache2 debería usar el puerto 8443 para HTTPS para que no haya conflictos. También he ajustado el DocumentRoot en consecuencia, pero esto depende de la configuración de su servidor y donde se encuentran todos los archivos para el sitio web.

```
<VirtualHost *:8443>
DocumentRoot /var/www/html/intranet
```

Con el siguiente comando configuramos Apache2 para HTTPS con nuestro fichero de configuración:

```
sudo a2ensite pi-server.lan.combined.conf
```

Para asegurarnos de que estos cambios se aplican y se activan, reiniciamos el servidor Apache2 con el siguiente comando:

```
sudo systemctl restart apache2.service
```

Ahora también hemos configurado con éxito el servidor web Apache2 para HTTPS y ahora debemos ocuparnos de los dispositivos finales que obtienen acceso seguro al servidor web.

## Importar el certificado raíz en MacOS

En primer lugar, tenemos que copiar el certificado raíz de la autoridad de certificación, es decir, la Raspberry Pi, a mi Mac local.

Dado que he guardado todos mis certificados en **/root/certs** y no tengo acceso allí con mi cuenta de usuario a través de `ssh` sin `sudo`, tengo que copiar primero el certificado a mi directorio **home** en la Raspberry Pi.

Para ello, utilizamos el siguiente comando, como ya estoy en mi directorio **home**:

```
sudo cp /root/certs/myCAnew.pem .
```

Ahora podemos cambiar el sistema. Como tengo MacOS, también uso el terminal para la transferencia allí y también me quedo en mi directorio **home**. Con el siguiente comando copiamos el archivo **myCAnew.pem** de la Raspberry Pi al Mac Studio:

```
rsync -avzh user@pi-server.lan:myCAnew.pem .
```

A continuación, encontramos nuestro certificado raíz en el directorio **home** del Mac Studio y podemos añadirlo al llavero. Para ello, abrimos el archivo **myCAnew.pem** con el llavero a través del Finder y lo añadimos al sistema.

Ahora sólo tenemos que hacer doble clic en el certificado en el llavero. En mi caso, es **pi-server.lan** y se abre una nueva ventana con toda la información sobre este certificado.

En la parte superior, abrimos la pestaña Confiar y seleccionamos "Confiar siempre" **cuando usemos este certificado**. Tenemos que volver a introducir la contraseña del sistema MacOS y se aplica la configuración.

Nuestro primer dispositivo final ya está totalmente configurado y debería clasificar el certificado de nuestro servidor web como fiable y seguro.

La integración de un certificado raíz puede ser ligeramente diferente para cada dispositivo final y sistema operativo. En cualquier caso, funcionó perfectamente en mi Mac Studio con MacOS 14.5.

## Importar el certificado raíz en Windows

En Windows, son necesarios algunos pasos más para instalar el certificado raíz. Se gestiona a través de la Consola de Administración de Microsoft, que podemos abrir más fácilmente con **Windows + R** y luego introduciendo **mmc**.

Allí también hay que configurar primero el entorno. Para ello, hacemos clic en Archivo y **Añadir snap-in** en el menú para seleccionar los certificados de la parte izquierda y los movemos a los snap-ins seleccionados de la parte derecha con **Añadir**. Seleccionamos **Cuenta de equipo** una vez y luego **Equipo local**, pulsamos **Finalizar** y confirmamos con **Aceptar**.

Ahora vemos **Certificados (equipo local)** a la izquierda debajo de la raíz de la consola y debajo encontramos la carpeta de **Autoridades de certificación raíz de confianza**. Hacemos clic con el botón derecho sobre ella y seleccionamos **Todas las tareas > Importar** en el menú.

Se inicia un asistente y hacemos clic una vez en **Siguiente** y luego en **Buscar** para seleccionar nuestro certificado raíz (myCAnew.pem). A continuación, hacemos clic en **Siguiente** y dejamos el almacén de certificados para las **Autoridades de certificación raíz de confianza** y volvemos a hacer clic en **Siguiente**.

Se vuelve a mostrar un resumen y podemos completar la importación con **Finalizar**. El certificado raíz se ha importado correctamente y podemos acceder a nuestro servidor web a través de un navegador, la conexión se muestra como segura y el certificado es válido.

## Importar el certificado raíz en Android

La importación en Android me llevó el mayor tiempo y esfuerzo. Como ya se ha descrito, ha habido un cambio en el sistema en la versión 10 de Android y los certificados raíz ya no se importan sin la bandera **CA:TRUE**. Sin embargo, hemos creado y cumplido los requisitos necesarios con nuestra documentación.

Por ejemplo, podemos enviar nuestro certificado raíz **myCAnew.pem** por correo electrónico y guardarlo localmente en Descargas. A continuación, importarlo a través de la configuración de seguridad del sistema y el certificado se puede utilizar.

Este [enlace](https://stackoverflow.com/questions/57565665/one-self-signed-cert-to-rule-them-all-chrome-android-and-ios/57684211#57684211) al final me ayudó a encontrar una solución. El proceso muy simple descrito allí también funciona, pero al final me sentí un poco demasiado inseguro y me quedé con la configuración más compleja como se describe aquí en mi entrada del blog.

## Importar el certificado raíz en iPadOS

En el iPad de Apple, el certificado **myCAnew.pem** se puede guardar en iCloud y acceder desde allí. Esto cargará un perfil, que será directamente visible en los ajustes.

Allí podremos seleccionar "Perfil cargado" y se mostrará la información sobre el certificado. Si estamos seguros de que se trata de nuestro certificado raíz, podemos tocar **Instalar** en la esquina superior derecha.

Para instalar un certificado raíz se nos pedirá la contraseña del iPad. En cuanto la hayamos introducido, aparecerá un aviso de que la instalación añadirá este certificado a la "lista de certificados de confianza" del iPad.

Lo deseamos y volvemos a pulsar **Instalar**. A continuación, pulse de nuevo **Instalar**.

El certificado se ha instalado correctamente y aparece una marca de verificación verde junto a **Verificado** :white_check_mark:

A continuación, podemos tocar en **Hecho** y ahora encontrar el certificado como **Perfil de configuración** en "General" y "VPN y gestión de dispositivos" en los ajustes de iPadOS. También puede eliminar el certificado raíz allí en cualquier momento.

Ahora tenemos que ir a **General** >> **Info** >> **Configuración de confianza de certificados** en los ajustes y activar **confianza total para certificados raíz** pulsando el interruptor junto a nuestro **pi-server.lan**. Aparece otro mensaje de advertencia y lo confirmamos con **Siguiente**.

Ya hemos instalado correctamente nuestro certificado raíz en iPadOS 17.5.1 y ahora tenemos una conexión segura cuando accedemos a nuestro servidor web local a través del navegador.

## Cierre y éxito

Ahora hemos instalado todos los certificados necesarios y deberíamos ser capaces de llegar a nuestro servidor web con los dominios o direcciones IP correspondientes y ya no recibir un mensaje de advertencia.

Puedo acceder a mis páginas web de la siguiente manera

`https://pi.hole/` para nuestra interfaz web Pi-Hole.

`https://pi-server.lan:8443` para nuestra intranet.

Por supuesto, podría haber ejecutado ambos a través de un único servidor web, pero ya estaba ejecutando mi intranet con Apache2 y la instalación de Pi-Hole instaló automáticamente el servidor Lighttpd junto con php.

No uso php en absoluto para mi intranet. Probablemente volveré a desinstalar Apache2 en algún momento y ejecutaré todo a través del servidor Lighttpd.

Espero que esta entrada del blog os ayude con vuestros proyectos y me sirva de documentación por si tengo que volver a ella en algún momento porque se me ha olvidado algo.

Nunca se sabe :sweat_smile:

¿Quizás te das cuenta de algo que podría haber hecho mejor o que quizás debería cambiar por razones de seguridad?

Házmelo saber en los comentarios. Muchas gracias.

Saludos cordiales
Sebastian

## Recursos

Los siguientes enlaces fueron útiles para mi autoridad de certificación:

- Hacer Pi-Hole HTTPS capaz con Lighttpd - [Enlace](https://mojo.lichtfreibeuter.de/pihole-mit-lighttpd-server-ssl-https-faehig-machen/)
- Firmar certificados SSL - [Enlace](https://mojo.lichtfreibeuter.de/ssl-zertifikate-selbst-signieren-root-und-client-zertifikate-erstellen/)
- Usar módulos Apache2 - [Enlace](https://ubuntu.com/server/docs/how-to-use-apache2-modules)
- Instalar certificados MacOS - [Enlace](https://flaviocopes.com/macos-install-ssl-local/)
- Resolver problemas de Android - [Enlace](https://stackoverflow.com/questions/57565665/one-self-signed-cert-to-rule-them-all-chrome-android-and-ios/57684211#57684211)
- Autoridad de certificación raíz en la LAN - [Enlace](https://www.markjunghanns.de/de_DE/index.php/2016/08/18/eine-eigene-root-zertifizierungsstelle-fuer-die-nutzung-im-lan-erstellen/)

{{< chat how-do-we-sign-our-ssl-certificates-with-openssl-for-local-web-services >}}
