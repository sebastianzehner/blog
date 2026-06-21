+++
title = 'Cómo cargar y publicar un sitio web Hugo'
summary = 'En la segunda parte de esta serie creamos algo de contenido para tu sitio web Hugo gratuito y hoy queremos subir y publicar este contenido en internet de forma gratuita.'
date = 2024-12-06T15:00:00-03:00
lastmod = 2024-12-06T15:00:00-03:00

tags = ['Hugo', 'sitio web', 'PaperMod']
categories = ['TechLab']

showComments = true
chatId = "how-to-upload-and-publish-a-hugo-website"
+++

En la [segunda parte de esta serie](/es/posts/how-to-create-content-for-your-free-hugo-website/) creamos algo de contenido para tu sitio web Hugo gratuito y hoy queremos subir y publicar este contenido en internet de forma gratuita.

## Preparar Git y crear un repositorio GitHub

Primero tenemos que subir todos los archivos a un repositorio GitHub. Git debe estar instalado en tu ordenador. Asegúrate de que estás en el directorio raíz de tu sitio web en tu máquina local utilizando el terminal y luego utiliza el siguiente comando:

```
git init
```

Ahora se inicializa un repositorio GitHub. A continuación, crea un archivo `.gitmodules` en la misma carpeta.

```
touch .gitmodules
```

El tema PaperMod debe ser un submódulo en el repositorio GitHub, así que escribe en el archivo `.gitmodules` esto:

```
[submodule "themes/PaperMod"]
 path = themes/PaperMod
 url = "https://github.com/adityatelange/hugo-PaperMod.git"
```

### Crear una cuenta gratuita en GitHub

Si aún no tienes una cuenta gratuita en GitHub, regístrate ahora y crea tu repositorio para tu sitio web. [Enlace a GitHub](https://github.com)

### Crea un token para un inicio de sesión seguro

Se necesita un token para el inicio de sesión seguro con Git en GitHub. Genera un nuevo token en GitHub.
[Enlace a la configuración de GitHub.](https://github.com/settings/tokens)

> Nota: yourname website
> Expiration: 90 days
> [x] public_repo

A continuación, pega estos comandos en el terminal:

```
echo "# yourname" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/yourname/blog.git
git push -u origin main
```

Escriba el nombre de usuario y el token si se le pide. Ahora los archivos se subirán al repositorio de GitHub.

### Cómo guardar y actualizar el token después de 90 días

Guarde este token en el Llavero del Mac: Haga clic en el icono Spotlight (lupa) a la derecha de la barra de menú.

Escribe Acceso a Llaveros y pulsa la tecla Intro para iniciar la aplicación:

- En Acceso a Llaveros, busca github.com.
- Encuentra la entrada de la contraseña de Internet para github.com.
- Edita o elimina la entrada según corresponda.
- Ya está.

> Nota: ¡Ahora Git puede subir archivos a GitHub sin errores!

Después de 90 días, genera un nuevo token en github.com e intercambia el token antiguo en el Llavero con el nuevo token generado.

Tal vez borrar primero el token antiguo del Llavero y luego hacer un comando push con nombre de usuario y contraseña/token. Una vez que este comando haya tenido éxito, cree una nueva entrada en el Llavero del Mac o restaure la antigua y sustituya el token antiguo por el nuevo.

> Nota: Esto funciona de forma similar con otros sistemas operativos.

## ¿Dónde desplegar el sitio web?

A continuación crea una cuenta gratuita en Netlify: [https://www.netlify.com/](https://www.netlify.com/)

- Nuevo sitio desde Git y conéctate con GitHub.
- Elige el repositorio del sitio web.

Despliega como tunombre en tunombreequipo desde la rama principal usando el comando hugo y publicando al público. Despliega tu nombre en Netlify.

Hubo un problema con el gitsubmodule y el siguiente comando resolvió este problema. Utilice el directorio raíz del sitio web local en el terminal.

```
git submodule update --remote –init
```

El enlace ahora tiene otro número detrás de `tree` y funcionó para mí.

Desplegar de nuevo con Netlify y ahora debería funcionar. **¡El sitio web está en línea!**

👉 <https://sebastianzehner.netlify.app>

## Registrar y conectar un dominio al sitio web

Utilizo [Hostinger](https://bit.ly/3W9oyZG) para el registro y la renovación de dominios. Los dos primeros años, Hostinger ofrece un precio especial por sólo 4,99 USD al año.

Después de dos años, el precio normal es de 15,99 USD al año por un dominio **.com**. Sólo me queda un dominio y quiero utilizarlo para mi nuevo sitio web.

Podemos [pagar por este dominio en cripto](/es/posts/how-i-paid-for-my-domain-with-cryptocurrency/) por uno, dos o tres años. Eso me gusta y son los únicos costes de nuestro nuevo sitio web porque el alojamiento con Netlifly y GitHub es gratuito. El software Hugo y el tema PaperMod son de código abierto y también de forma gratuita.

En el sitio web Netlify en el backend configuramos un dominio personalizado. Añadir un dominio personalizado a su sitio y pulse verificar y luego añadir dominio. En la gestión de dominios recibí algunos ajustes DNS.

```
Point A record to xx.x.xx.x for yourdomain.com
```

Cambié la dirección IP para mi dominio en Hostinger en los registros DNS para el tipo A apuntado a xx.x.xx.x y guardé estos ajustes.

Después de unos minutos Netlify registró estos cambios y ahora mi sitio web es accesible bajo <http://sebastianzehner.com> y <http://www.sebastianzehner.com> redirige a <http://sebastianzehner.com>. Pero esto no es seguro y tenemos que configurar un cifrado.

## Habilitar el certificado TLS: Let's Encrypt

En la gestión de dominios en el backend desde Netlify verifiqué la configuración DNS para el certificado SSL/TLS. Sólo un clic en el botón y la verificación de DNS se ha realizado correctamente ✅

Y ya está. Así de fácil. Ahora la conexión es segura y el sitio web accesible con mi dominio [https://sebastianzehner.com](https://sebastianzehner.com)

Mientras tanto la gestión de dominios en Netlify dice:

- Su sitio tiene HTTPS habilitado ✅

Último paso para configurar este nuevo dominio en el archivo de configuración `hugo.toml`. Inserta o renombra esta línea:

```
baseURL = 'https://yourdomain.com'
```

Sube estos cambios a internet con un `git push` y ya está.

Nuestro nuevo seguro y minimalista sitio web Hugo con el tema PaperMod está en línea y los visitantes son bienvenidos a leer mis cosas interesantes 😎

Gracias por leer mi blogpost y tener un buen día. Seguiré en el próximo episodio de esta serie con uno de estos temas: shortcodes, función de búsqueda o analítica con GoatCounter.

Saludos Sebastian

## Vídeo: Primeros pasos con Hugo

Este gran video ayuda en la mayoría de los puntos. El submódulo era complicado y me costó mucho tiempo, pero ahora está todo bien y funcionando.

{{< youtube hjD9jTi_DQ4 >}}

## Otros sitios y enlaces útiles

- Transformar yaml a toml [Link](https://transform.tools/yaml-to-toml)
- Markdown Cheat Sheet [Link](https://www.markdownguide.org/cheat-sheet/)
- Menús multilingües [Link](https://gohugo.io/content-management/multilingual/#menus)
- Front matter [Link](https://gohugo.io/content-management/front-matter/)
- PaperMod Features [Link](https://github.com/adityatelange/hugo-PaperMod/wiki/Features)
