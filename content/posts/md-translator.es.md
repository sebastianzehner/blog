---
title: El desafío de los blogs multilingües
summary: Los blogs multilingües implican un esfuerzo de traducción. Las traducciones manuales son costosas y las herramientas automáticas suelen dañar el formato Markdown. ¿Cómo mantener la eficiencia y conservar el formato?
date: 2025-12-17T17:00:00-03:00
lastmod: 2025-12-17T17:00:00-03:00
draft: false
tags:
  - hugo
  - markdown
  - blogging
  - ai
  - llm
  - claude
categories:
  - tech

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/md-translator.webp
  alt: El blogger gestiona un blog multilingüe (en alemán, inglés, español y francés) desde su ordenador portátil
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2025-12-17
  time: "18:08:11"
---

Como blogger que tiene un blog multilingüe, uno se enfrenta a un reto constante: cada nuevo artículo debe ser traducido a varios idiomas. Las traducciones manuales son laboriosas y costosas, mientras que las herramientas automáticas a menudo dañan la estructura del texto (formatada con Markdown) que se ha creado con cuidado. ¿Qué hacer?

Precisamente frente a este problema me encontré cuando comencé a publicar mi blog en alemán, inglés y español. La solución: un traductor inteligente de Markdown que mantiene la estructura original de los textos y ofrece traducciones de alta calidad.

## El proceso de creación de md-translator

md-translator es una herramienta basada en Python que traduce archivos en formato Markdown utilizando inteligencia artificial (IA), sin alterar su formato original. Lo especial de esta herramienta es que utiliza el modelo de traducción Hunyuan-MT-7B de Tencent, un modelo especializado con 7 mil millones de parámetros que actualmente soporta 38 idiomas.

La solución se desarrolló paso a paso y se modificó continuamente. Al principio, el objetivo era sencillo: traducir un archivo en formato Markdown. Sin embargo, rápidamente surgieron varios problemas o dificultades.

- Los bloques de código han sido traducidos… ¡y el resultado es catastrófico!
- Los enlaces se desintegraron en sus componentes individuales.
- Las tablas perdieron su estructura.
- El contenido del «Front Matter» ha sido completamente desordenado.
- Las rutas de URL no se ajustaban a la estructura multilingüe del blog.

Cada uno de estos problemas dio lugar a la creación de una nueva función, a la corrección de un nuevo error (bug) o a alguna mejora en el funcionamiento del software. El resultado es una herramienta muy fiable que ahora se encuentra en su versión 1.2.3.

## Desarrollo junto a Claude Code

El traductor md-translator no se desarrolló de forma independiente; utilicé Claude Code, el asistente de programación de IA de Anthropics, en el terminal. Esta colaboración entre humano e inteligencia artificial fue la clave del éxito.

### El proceso de desarrollo

El proceso de desarrollo se llevó a cabo de manera iterativa a lo largo de varios días.

1. **Concepto inicial**: Definí los requisitos: un traductor de Markdown que mantuviera la estructura original del texto.
2. **Prototipado**: Claude Code escribió la primera versión del software, incorporando la lógica básica necesaria para el análisis (parsing) de los archivos en formato Markdown.
3. **Pruebas e iteraciones**: Realicé pruebas con artículos de blogs reales; detecté algunos problemas, y Claude Code implementó las soluciones correspondientes.
4. **Ampliación de las funcionalidades**: Cada nuevo problema daba lugar a una discusión sobre la mejor solución posible.

Lo que realmente me impresionó fue que Claude Code no solo comprendía el código en sí, sino también su contexto. Cuando le decía que “la formatación de las tablas no funcionaba correctamente”, él analizaba el problema, proponía una solución y la implementaba, teniendo en cuenta incluso los casos más complejos (los llamados “edge cases”).

### Los desafíos

No todo salió bien a la primera tentativa. El formato en negrita/cursiva fue un ejemplo perfecto de los límites que existen en este proceso.

- Probamos varios enfoques: sistemas de marcadores, normalización y etiquetas XML.
- Cada enfoque funcionó de manera parcial, pero no de manera consistente.
- Al final, decidimos juntos que la calidad de la traducción es más importante que una formatación perfecta.

Este proceso de toma de decisiones pragmático —que combina sugerencias basadas en la inteligencia artificial con el juicio humano— resultó de gran valor.

### Funcionaba de maravilla

La colaboración con Claude Code presentaba claros beneficios:

- **Velocidad**: Las funcionalidades que habrían requerido horas de desarrollo se implementaron en cuestión de minutos.
- **Calidad del código**: Código en Python limpio y bien estructurado, que incluye docstrings.
- **Resolución de problemas**: Se propusieron inmediatamente alternativas para resolver el problema.
- **Depuración iterativa**: Los errores se identificaron y se corrigieron rápidamente.

### El factor humano

A pesar del apoyo de la inteligencia artificial, mi papel fue decisivo.

- **Objetivo**: ¿Qué debería ser capaz de hacer esta herramienta?
- **Pruebas**: ¿Funciona realmente en la práctica?
- **Priorización**: ¿Qué funciones son importantes y cuáles no lo son?
- **Decisiones**: ¿Quitar el texto en negrita/italico? ¿O optar por una solución más compleja?

Claude Code es una herramienta muy potente, pero no un «piloto automático». Los mejores resultados se logran a través de la colaboración entre la experticia humana y las capacidades de la inteligencia artificial.

## ¿Cómo funciona md-translator?

### Segmentación inteligente

El traductor no simplemente interpreta los archivos en formato Markdown como texto normal, sino que también comprende su estructura.

- **Material preliminar**: Los metadatos en formato YAML se traducen de forma selectiva (únicamente el título, la descripción, etc.).
- **Títulos**: Los títulos se traducen y su jerarquía se mantiene.
- **Bloques de código**: Están completamente protegidos y no se traducen.
- **Tablas**: Se ha realizado la traducción celda por celda; la estructura general se mantiene intacta.
- **Enlaces**: El texto se traduce, pero la dirección URL (URL) permanece protegida.
- **Imágenes**: El texto alternativo («alt-text») se traduce, mientras que la ruta de la imagen permanece sin cambios.

### Protección de elementos

Ciertos elementos nunca deben ser traducidos.

- Código incrustado (inline code), como `variable_name`.
- Etiquetas HTML como `<div>` o `<span>`
- URLs en enlaces e imágenes
- Referencias a notas a pie de página, como `[^1]`.

Estos elementos se reemplazan por placeholders (sustitutos) antes de la traducción y luego se recuperan una vez finalizada esta. El modelo LLM (Large Language Model) nunca los ve.

### Interfaz de línea de comandos (CLI) inteligente

La interfaz de línea de comandos se ha diseñado de forma deliberadamente sencilla.

```bash
python md-translator.py artikel.de.md -l en es
```

La herramienta reconoce automáticamente:

- El idioma fuente, según el nombre del archivo (`artikel.de.md` → alemán):
- Genera automáticamente archivos de salida (`artikel.en.md`, `artikel.es.md`).
- Carga el modelo solo una vez para todas las traducciones.

## Características especiales

### Reescritura de URL para blogs multilingües

Un problema típico de los blogs multilingües: los artículos en alemán se encuentran bajo `/de/posts/my-article`, los en inglés directamente bajo `/posts/my-article` y los en español bajo `/es/posts/my-article`. Los enlaces internos deben ser adaptados en consecuencia.

El traductor MD resuelve este problema de manera elegante mediante un archivo de configuración opcional.

```yaml
url_rewriting:
  enabled: true
  patterns:
    de: /de
    en: ""
    es: /es
```

Un enlace como `/de/posts/my-article` se convierte automáticamente en `/posts/my-article` (en inglés) o `/es/posts/my-article` (en español).

### Metadatos de traducción

Cada archivo traducido recibe automáticamente metadatos en la sección «Front Matter».

```yaml
translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2024-12-16
  time: "14:23:45"
```

De esta manera, es comprensible saber cuándo y cómo se tradujo un archivo. Esto resulta muy práctico para blogs grandes que contienen cientos de artículos.

### Visualización automática en Hugo

Los metadatos de traducción no son solo una forma de documentación; también son de utilidad práctica. Mi blog Hugo analiza automáticamente estos datos y los muestra en el pie de página de cada publicación.

**Modificación del plantilla Hugo:**

El plantilla Hugo verifica si el campo `translation` existe en el «Front Matter» (el contenido inicial del documento). En caso afirmativo, se genera automáticamente un aviso al respecto.

```html
# singles.html {{ if .Params.translation }}
<div class="translation-note-wrapper">
  {{ partial "translation-note.html" . }}
</div>
{{- end }}
```

```html
# translation-note.html {{ with .Params.translation }} {{ $from := i18n (printf
"lang_%s" .from) }} {{ $to := i18n (printf "lang_%s" .to) }} {{ $toolPage :=
site.GetPage "posts/md-translator" }} {{ $toolName := .tool }} {{ if $toolPage
}} {{ $toolName = printf `<a href="%s">%s</a>` $toolPage.RelPermalink .tool |
safeHTML }} {{ end }} {{ i18n "translation_note" (dict "From" $from "To" $to
"Tool" $toolName "Version" .version ) | safeHTML }} {{ end }}
```

**Para el lector, esto se presenta de la siguiente manera:**

> Este artículo fue traducido de alemán a español usando md-translator v1.2.3.

Así, el lector puede saber de inmediato y de manera transparente qué sucede.

- ✅ Que está leyendo una traducción.
- ✅ ¿Qué herramienta se utilizó?
- ✅ ¿De qué idioma se tradujo al otro?
- ✅ ¿Cuándo se realizó la traducción?

Esto es especialmente útil en los artículos que se actualizan con frecuencia. Cuando el texto original es modificado, se puede volver a traducirlo y la fecha indica qué versión de la traducción es la más reciente.

### Normalización de los signos de puntuación

Un problema frecuente es que el modelo LLM (Large Language Model) a veces añade signos de puntuación en lugares donde no deberían estar. Por ejemplo, `Über mich` se convierte en `About me.`, lo que provoca la aparición de un punto no deseado.

El traductor MD verifica el texto original: si no hay ningún signo de puntuación al final, tampoco se añadirán en la traducción. Una lógica sencilla que tiene un gran efecto.

## Detalles técnicos

### Optimización para GPU

El modelo Hunyuan-MT-7B cuenta con 7 mil millones de parámetros. Para procesarlos con total precisión (formato FP32), serían necesarios aproximadamente 28 GB de RAM dedicada a la visualización en realidad virtual (VRAM); cantidad que supera con creces las capacidades de la mayoría de las tarjetas gráficas existentes.

La solución es utilizar el formato FP16 (medio de precisión). Esto reduce la necesidad de memoria a aproximadamente 14 GB y duplica la velocidad de ejecución. Por lo tanto, la traducción se realiza de manera muy fluida en una tarjeta gráfica RTX 4090.

### Posprocesamiento

Después de la traducción, todavía suceden algunas cosas más…

1. **Corrección de la sintaxis Markdown**: Los espacios de lectura que se encuentran entre `]` y `(` en los enlaces se eliminan.
2. **Restauración de la sintaxis de las imágenes**: Se complementan los segmentos que faltan (`!`) antes de las imágenes.
3. **Restauración de elementos sustitutos**: Los elementos protegidos se recuperan en su estado original.
4. Los textos de los enlaces se traducen por separado.

El resultado: archivos Markdown con un formato perfecto que se ven como si hubieran sido escritos a mano.

## Lecciones aprendidas

El desarrollo de md-translator fue muy instructivo. Algunas de las conclusiones a las que se llegó son las siguientes:

**Lo que funcionó fue:**

- Los marcadores de reemplazo (placeholder) como `__INLINECODE0__` son compatibles con los modelos de lenguaje natural de gran alcance (Large Language Models, LLM).
- La segmentación basada en la estructura del formato Markdown permite mantener el contexto adecuado de cada parte del texto.
- La optimización para el formato FP16 supone un verdadero cambio de juego en términos de rendimiento.
- La configuración mediante YAML hace que la herramienta sea flexible.

**Lo que no funcionó:**

- El formato en negrita/cursiva (`*` y `**`) no puede protegerse de manera fiable.
- El modelo LLM trata estos marcadores de manera inconsistente.
- A veces se conservan, y otras veces no.
- Aquí es necesaria una edición manual posterior.

**Lo que funcionó de manera sorprendentemente bien fue:**

- Traducción de tablas, celda por celda
- Reescritura de URL para estructuras multilingües
- Traducción del texto del enlace sin cambiar la URL

## Beneficios prácticos

Desde que comencé a utilizar md-translator, mi flujo de trabajo se ha simplificado drásticamente.

**Antes:**

1. Escribir artículos en alemán.
2. En la herramienta de traducción, haga clic en «Copiar».
3. Puedo encargar la traducción.
4. Reparar manualmente el formato Markdown.
5. Revisar y corregir los enlaces (links) y las imágenes.
6. Traducción manual del texto del «Front Matter».
7. Ajustar las URLs para que se refieran al idioma objetivo.
8. Repetición para cada idioma.

**Más tarde:**

```bash
python md-translator.py artikel.de.md -l en es
```

Es hora de escribir un artículo de 1000 palabras:

- Antes: entre 60 y 90 minutos (para 2 idiomas).
- Después: ~3–5 minutos (tiempo de traducción únicamente).

¡Esto representa un ahorro de tiempo de más del 90%!

## Código abierto y futuro

md-translator es de código abierto y está disponible en GitHub. La versión actual, 1.2.3, es estable y lista para su uso en entornos de producción.

Características planeadas para el futuro:

- Procesamiento por lotes de directorios completos
- Soporte para otros dialectos de Markdown

## En resumen

El md-translator demuestra cómo la inteligencia artificial moderna puede resolver problemas prácticos. No se trata de una herramienta perfecta (la formatación en negrita o cursiva sigue siendo un reto), pero ahorra mucho tiempo y proporciona traducciones de alta calidad.

Para los bloggers que publican contenidos en varios idiomas, esto supone un verdadero cambio de juego. Personalmente, me ha facilitado mucho publicar artículos en distintas lenguas. Y ese es precisamente el objetivo: hacer que el conocimiento esté al alcance de todos, sin importar el idioma.

## El carácter meta de este artículo

Este artículo es un ejemplo perfecto de desarrollo y creación de contenido modernos basados en la inteligencia artificial (IA).

**Historia de su creación:**

1. El traductor MD (md-translator) fue desarrollado en colaboración con **Claude Code**; la inteligencia artificial (IA) ayuda en el proceso de programación.
2. Este artículo fue escrito con la ayuda de **Claude Code** (la inteligencia artificial colabora en el proceso de escritura).
3. El artículo se traduce utilizando **md-translator** (una herramienta de inteligencia artificial que realiza la traducción automáticamente).
4. Es posible que estés leyendo la **versión traducida por IA** de este artículo.

Esto es, en pura forma, un ejemplo de “dogfooding”, y al mismo tiempo demuestra las posibilidades del trabajo basado en inteligencia artificial. Desde el código, pasando por el artículo, hasta la traducción: la IA como herramienta, controlada por la intención humana y por un proceso de control de calidad.

Si lees este artículo en inglés o español, al final verás una indicación sobre la traducción automática: ¡la integración de Hugo en acción!

---

**Especificaciones técnicas:**

- Lenguaje: Python 3.12
- Framework: PyTorch 2.5.0 con CUDA 12.4
- Modelo: [Tencent Hunyuan-MT-7B](https://github.com/Tencent-Hunyuan/Hunyuan-MT) (Parámetro de 7B, tipo FP16)
- Idiomas soportados: actualmente 38 idiomas.
- Licencia: MIT
- Repositorio: [github.com/sebastianzehner/md-translator](https://github.com/sebastianzehner/md-translator)

{{< chat md-translator >}}
