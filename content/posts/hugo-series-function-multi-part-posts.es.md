---
title: "Hugo: Función de serie para publicaciones de blog divididas en varias partes"
summary: "En consonancia con la serie de blogs que he planeado, he integrado una función de serie en Hugo. En este tutorial te mostraré cómo crear publicaciones divididas en varias partes, con numeración y navegación."
date: 2026-01-04T21:35:10-03:00
lastmod: 2026-01-04T21:35:10-03:00
draft: false
tags:
  - hugo
  - blogging
  - markdown
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/hugo-series-function-multi-part-posts.webp
  alt: "Hugo: Función de serie para publicaciones de blog divididas en varias partes"
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2026-01-06
  time: "11:08:16"
---

¿Quién no lo conoce? A veces, un solo artículo de blog no es suficiente para tratar un tema en profundidad. Entonces se escribe una serie de artículos dividida en varias partes, pero ¿cómo pueden los lectores orientarse? Aunque Hugo ofrece categorías y etiquetas de forma predeterminada, no cuenta con una función nativa que permita visualizar el progreso y el orden de la serie de artículos.

Hace poco resolví este problema para mi blog e implementé una función de series. En esta guía te mostraré cómo puedes hacerlo tú mismo de manera muy sencilla utilizando los herramientas de Hugo.

## ¿Por qué incluir una función de serie?

Cuando un lector encuentra parte de una serie, generalmente quiere saber tres cosas:

1. Que este post forma parte de una serie más extensa.
2. ¿Qué parte está leyendo en estos momentos? (Por ejemplo, la Parte 2 de un total de 5).
3. Donde se encuentran los enlaces a las otras partes de la serie.

## Paso 1: Registrar la serie en Hugo

Primero, debemos informar a Hugo de que, además de las etiquetas y las categorías, ahora también existen las «series». Para ello, completa tu código `hugo.yaml` de la siguiente manera:

```yaml
taxonomies:
  categories: categories
  tags: tags
  series: series
```

## Paso 2: Crear el componente parcial (Partial)

Vamos a crear un «elemento de código» reutilizable (un «partial»). Para ello, genera el archivo ``layouts/partials/series.html`` y añade el siguiente código:

```html
{{ $series := .GetTerms "series" }}
{{ if $series }}
    {{ range $series }}
    {{ $posts := .Pages.ByDate }}
    {{ $count := len $posts }}
    <aside class="series-container">
        <details {{ if lt $count 5 }}open{{ end }}>
            <summary class="series-summary">
                <div class="series-header-text">
                    <span class="series-title">
                        {{ i18n "series_title" }}: {{ .Name }}
                    </span>
                    <span class="series-count">
                        {{ i18n "series_parts_total" $count }}
                    </span>
                </div>
            </summary>
            <ul class="series-list">
                {{ range $num, $post := $posts }}
                    {{ $isCurrent := eq $post.Permalink $.Page.Permalink }}
                    <li class="series-item">
                        <span class="series-part-label">
                            {{ i18n "series_part" }} {{ add $num 1 }}
                        </span>
                        {{ if $isCurrent }}
                            <span class="series-item-current" aria-current="page">
                                 {{ i18n "series_current" }}
                            </span>
                        {{ else }}
                            <a href="{{ $post.Permalink }}" class="series-item-link">
                                {{ .Params.series_title | default .Title }}
                            </a>
                        {{ end }}
                    </li>
                {{ end }}
            </ul>
        </details>
    </aside>
    {{ end }}
{{ end }}
```

**El código en detalle:**

- Comenzamos con ``.GetTerms "series"``: Esta instrucción accede a la taxonomía. Si un artículo está asignado a varias series, el código, gracias al bucle ``range`` que sigue, renderizará una caja separada para cada una de ellas.

- **Ordenación (`.Pages.ByDate`):** Por defecto, Hugo muestra las páginas a menudo según un criterio de ponderación o en orden descendente por fecha. Con `.ByDate`, nos aseguramos de que la serie se presente de manera lógica, de principio a fin (Parte 1, Parte 2, Parte 3…).

- **Estado dinámico de la caja**: Esta es una funcionalidad muy práctica y cómoda. Si la serie tiene pocos episodios (menos de 5), la caja permanece abierta. En el caso de series muy largas, se cierra para no interrumpir la lectura.
```html
<details {{ if lt $count 5 }}open{{ end }}>
```

- **Numeración automatizada**: No es necesario introducir manualmente el número del componente en la sección frontal (frontmatter). En este caso, Hugo utiliza el índice de la bucla (que comienza en 0) para calcular el número del componente de forma directa, utilizando la expresión ``+ 1``.
```html
{{ range $num, $post := $posts }} ... {{ add $num 1 }}
```

- **Idioma con `i18n`:** Para que los textos (como “Parte 1”) funcionen en diferentes idiomas, utilizamos la función de internacionalización de Hugo.

- **Gestión flexible de los títulos**: En este caso utilizamos un mecanismo basado en “pipelines” (canales de comunicación). Si en el artículo se define un código especial (``series_title``, por ejemplo, para crear un título más corto para la lista), se utiliza ese código. De lo contrario, Hugo recurre automáticamente al código normal (``.Title``).
```html
{{ .Params.series_title | default .Title }}
```

- **Lógica del post actual:** El código verifica si el enlace que se encuentra en la lista es el del post actual (`$isCurrent`). En caso afirmativo, dicho enlace se resalta, pero no es posible hacer clic en él.

## Paso 3: Integración en el template

Para que la caja también se muestre, debes incorporar el código correspondiente en tu plantilla de publicación individual (generalmente ``layouts/_default/single.html``). Lo he colocado justo antes del contenido.

```html
{{ partial "series.html" . }}
<div class="post-content">
  {{ .Content }}
</div>
```

## Paso 4: Archivos de idioma y configuraciones de estilo

Para que los términos se traduzcan correctamente, añade esto a tus archivos `i18n` en el idioma correspondiente.

```yaml
- id: series_part
  translation: "Teil"
- id: series_title
  translation: "Dieser Artikel ist Teil der Serie"
- id: series_current
  translation: "Aktueller Beitrag"
- id: series_parts_total
  translation:
    one: "Teil insgesamt"
    other: "{{ .Count }} Teile insgesamt"
```

No olvides agregar algo más de estilo a tu código ``post-single.css`` para que la caja se ajuste visualmente a tu blog (por ejemplo, espacios entre elementos, bordes o colores de fondo).

## Uso en el artículo del blog (parte inicial)

Para asignar una publicación a una serie, simplemente completa el «frontmatter» (el texto que se muestra al principio del artículo).

```ini
series:
  - Roadtrip Spanien und Portugal
# Título más corto opcional para la lista
series_title: Camping mit dem Wohnmobil durch Spanien und Portugal
```

## Perspectivas futuras: ¿Qué vendrá a continuación?

Utilicé directamente esta función para reorganizar mi archivo [cuatro publicaciones anteriores sobre el viaje por carretera por España y Portugal](/es/posts/road-trip-trough-spain-and-portugal-in-a-motorhome-part-1/). ¡No duden en echarle un vistazo!

La razón real de esta remodelación es, sin embargo, otro proyecto que pronto comenzará a desarrollarse: una nueva y extensa serie sobre el tema de la **“libertad en el uso de los correos electrónicos”**.

Se tratará de determinar si y cómo es posible liberarse de los grandes proveedores de servicios tecnológicos, así como de explorar las alternativas disponibles a la opción de hospedar uno mismo los sistemas en el propio entorno doméstico (homelab). El tema no solo tiene un enfoque técnico, sino también un aspecto filosófico: ¿Hemos perdido ya nuestra libertad en lo que respecta al uso del correo electrónico?

Gracias a la nueva función de series, ¡con suerte podrán mantener siempre el control de lo que están viendo! Todas mis series pueden encontrarse a partir de ahora en [Series](/es/series); por cierto, este enlace también está disponible en [Página la visión general](/es/overview/).

¿Qué pensáis? ¿Usáis también series para vuestros blogs, o os basta con la clásica presentación de contenidos en forma de tag cloud? No dudéis en escribírmelo en los comentarios.

¡Me alegro mucho de recibir vuestros comentarios!

{{< chat hugo-series-function >}}
