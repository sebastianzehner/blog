---
title: 'De PaperMod a Blowfish: ¿Por qué cambié mi tema Hugo?'
summary: >-
  Después de años con PaperMod, cambié mi blog de Hugo a Blowfish. Lo que me
  convenció, qué es diferente y por qué Catppuccin juega un papel importante.
date: 2026-06-22T21:25:07.000Z
lastmod: 2026-06-22T21:25:07.000Z
tags:
  - hugo
  - blowfish
  - blogging
  - website
  - catppuccin
categories:
  - techlab
showComments: true
chatId: blowfish
translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2026-06-22T00:00:00.000Z
  time: '17:52:19'
---
Quienes conocen mi blog desde hace tiempo probablemente no se hayan dado cuenta
de este cambio de inmediato, y eso es precisamente una buena señal. Los
contenidos siguen siendo los mismos, al igual que las URL. Lo que ha cambiado es
el “fundamento” sobre el que se basa todo: **el tema utilizado de Hugo**.

Durante mucho tiempo, este blog funcionó sin problemas:

{{< github repo="adityatelange/hugo-PaperMod" showThumbnail=true >}}

Un tema delgado, rápido y muy popular para [Hugo](https://gohugo.io/).

PaperMod ha hecho su trabajo muy bien, y yo también estaba satisfecho con el
resultado. Con el paso del tiempo, he realizado algunas modificaciones y
adiciones al código original. Además, una actualización de Hugo introdujo
cambios en los parámetros de idioma que tuve que adaptar.

Por casualidad, me topé con Blowfish, y lo que vi allí me llamó la atención de
inmediato. No porque PaperMod fuera malo, sino porque Blowfish incluye algunas
funciones muy útiles que mejoran directamente la facilidad de uso del blog; esas
funciones habría tenido que crearlas yo mismo en PaperMod.

## Lo que me convenció de Blowfish

[Blowfish][1] es un tema moderno para Hugo creado por [Nuno Coração][2], que se
basa en Tailwind CSS y tiene un aspecto mucho más actual que PaperMod. No solo
su apariencia me ha convencido, sino también las funciones que realmente marcan
la diferencia en el uso diario.

**Alertas al estilo de GitHub**, directamente en Markdown, y sin necesidad de usar
códigos cortos propios.

> [!NOTE]
> Así es como se ve una nota escrita directamente en Markdown.

Con PaperMod habría tenido que escribir mi propio código corto (shortcode) y
código CSS para ello. Con Blowfish, simplemente escribo `> [!NOTE]` y ya está listo.

**Tarjetas de repo** para GitHub, Forgejo y Codeberg; **soporte para iconos**;
búsqueda integrada que funciona como una capa adicional sobre la pantalla;
**modo Zen** para una lectura sin distracciones; **opciones de accesibilidad**
(tamaño de la fuente, efecto de desenfoque, resaltado de los enlaces), y todo
esto viene incluido de forma predeterminada en Blowfish, sin que yo tenga que
hacer nada más.

Además, cuenta con una comunidad muy activa y una [documentación][3] que es
realmente de excelente calidad.

{{< github repo="nunocoracao/blowfish" showThumbnail=true >}}

## La migración: más trabajo del esperado, pero vale la pena

Sería deshonesto si dijera que la migración fue sencilla. Blowfish tiene una
estructura de configuración diferente a la de PaperMod; en lugar de un único
archivo `hugo.yaml`, existen varios archivos bajo `config/_default/`:

```bash
config/_default/
├── hugo.toml
├── languages.de.toml
├── languages.en.toml
├── languages.es.toml
├── markup.toml
├── menus.de.toml
├── menus.en.toml
├── menus.es.toml
└── params.toml
```

Al principio, puede parecer que requiere más esfuerzo, pero a largo plazo
resulta mucho más sencillo de manejar, especialmente en un blog multilingüe como
el mío.

La tarea realmente laboriosa fue la migración de todos los artículos a los
**Page Bundles**: en lugar de tener archivos individuales con el formato `.md`,
cada artículo ahora dispone de su propio directorio que contiene los `index.md`,
`index.de.md` y `index.es.md`, así como todas las imágenes correspondientes,
ubicadas directamente al lado de estos códigos. Esto hace que el proyecto sea,
en general, mucho más organizado.

```bash
content/posts/my-blogpost/
├── background.webp
├── featured.webp
├── index.de.md
├── index.es.md
└── index.md
```

## Lo que yo construí y lo que Blowfish ya incluye

Con PaperMod no quedé satisfecho con el diseño o las funcionalidades estándar,
por lo que con el tiempo construí y adapté varias cosas por mi cuenta: un índice
de contenidos (TOC) ampliado, una función para artículos divididos en partes,
así como la integración de [Cactus Comments][5], un sistema de comentarios
seguro desde el punto de vista de la protección de datos basado en la tecnología
Matrix.

Blowfish incorpora de forma predeterminada el tabla de contenidos (TOC) y las
series correspondientes; todo es configurable a través de `params.toml`, por lo
que no es necesario utilizar código de plantillas propio. Esto me ahorró tener
que crear varios componentes partials de forma manual, los cuales pude eliminar
fácilmente tras la migración.

Sigo utilizando los comentarios de Cactus, ya que se adaptan perfectamente a mi
propio servidor [Matrix Homeserver][6]. La integración ahora se realiza a través
del hook oficial `comments.html` de Blowfish; el proceso es más sencillo que
antes, y además pude instalar de inmediato la nueva versión de Cactus, que
soporta el multilingüismo y el mecanismo `isAuthenticated`.

Esto último fue especialmente importante: gracias a ello, pude reactivar el
código `enable_authenticated_media: true` desde el lado en Synapse, lo que
mejoró significativamente la seguridad de los medios.

## El esquema de colores de Catppuccin

Quienes conozcan mi blog sabrán que [Catppuccin][4] es mi paleta de colores
favorita, tanto en Terminal como en Neovim, así como en mi propio blog. Blowfish
permite utilizar propios esquemas de colores a través de un sencillo archivo CSS
ubicado en la carpeta `assets/css/schemes/catppuccin.css`.

Lo especial es que Blowfish utiliza Tailwind CSS, junto con variables CSS, para
definir todos los colores. Esto permite representar de manera clara y precisa
los estilos visuales de Catppuccin Latte (modo claro) y Catppuccin Mocha (modo
oscuro):

- `--color-neutral-*` para colores de fondo y texto
- `--color-primary-*` para el color azul (enlaces y botones)
- `--color-secondary-*` para el color mauve (código en línea y badges)

El resultado es un blog que se siente completamente a gusto en todo mi entorno
Linux en casa.

## Lo que echo de menos

La honestidad es importante a la hora de hacer comparaciones: PaperMod era más
rápido. Se trata de un tema minimalista que no impone mucha carga adicional al
sistema, lo cual se nota en los tiempos necesarios para su instalación y en el
peso de las páginas web resultantes. Por otro lado, Blowfish incluye más código
JavaScript y CSS; no es algo dramático, pero merece ser mencionado.

Además, Blowfish se basa en Tailwind; esto implica que quienes deseen realizar
modificaciones personalizadas deben conocer las clases de Tailwind o estar
dispuestos a aprender algo nuevo. No es un inconveniente, pero constituye una
diferencia con PaperMod, donde simplemente se podían sobrescribir las variables
CSS.

## En resumen

El cambio ha valido la pena. Blowfish es más moderno en términos visuales,
cuenta con más funciones y permite realizar muchas cosas que, de otra manera,
tendría que crear yo mismo en PaperMod. La migración fue compleja, pero ha
resultado satisfactoria; ahora el blog se encuentra sobre una base sólida.

Para quienes utilizan Hugo y están pensando en qué tema elegir, les recomiendo
que echen un vistazo a [blowfish.page][1]. La página de demostración muestra
muchas de las funcionalidades en vivo, y es sencillo comenzar a usarlo gracias a
la documentación detallada disponible.

Si tienes preguntas sobre la migración o sobre cómo adaptar el código
Catppuccin, ¡escribe un comentario con gusto!

[1]: https://blowfish.page/
[2]: https://github.com/nunocoracao
[3]: https://blowfish.page/docs/
[4]: https://catppuccin.com/
[5]: /posts/cactus-comments-blog-comments-matrix-server/
[6]: /posts/self-hosting-matrix-homeserver-synapse/

{{< translation-note >}}

