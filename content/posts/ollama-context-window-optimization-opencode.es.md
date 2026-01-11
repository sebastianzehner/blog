---
title: "Optimización de la ventana de contexto de Ollama: la clave para una integración exitosa de OpenCode"
summary: El Context Window limita muchos setups de Ollama. Tres métodos de optimización, pruebas prácticas y recomendaciones concretas para usar OpenCode con LLMs locales.
date: 2026-01-10T19:20:00-03:00
lastmod: 2026-01-10T19:20:00-03:00
draft: false
tags:
  - ollama
  - llm
  - opencode
  - open-source
  - terminal
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/ollama-context-cover.webp
  alt: Ventana de contexto de Ollama
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: es
  date: 2026-01-10
  time: "21:18:08"
---

Ollama se ha establecido como una solución popular para ejecutar modelos de lenguaje de gran tamaño (Large Language Models, LLMs) de forma local en la propia hardware. Sin embargo, muchos usuarios se encuentran con problemas misteriosos al integrarlo con herramientas como OpenCode.

Las funciones de tipo “Tool Calls” no funcionan correctamente; los agentes pierden el contexto necesario para llevar a cabo sus tareas, y la generación de código queda muy por debajo de las expectativas. La causa de estos problemas suele no residir en el modelo en sí, sino en un parámetro a menudo pasado por alto: la **ventana de contexto** (Context Window).

## El problema de la ventana de contexto: ¿por qué no son suficientes 4096 tokens?

Ollama utiliza por defecto una ventana de contexto que contiene únicamente 4096 tokens, independientemente del tamaño teórico del modelo. Este valor puede ser suficiente para interacciones de chat sencillas, pero se convierte en un obstáculo importante cuando se tratan tareas más complejas.

Para aplicaciones exigentes, como:

- Generación de código y refactorización
- Llamada a una herramienta que contiene varias funciones
- Flujos de trabajo basados en agentes
- Integración con OpenCode

Este estándar es, en la práctica, siempre demasiado reducido. El modelo no puede hacer uso de su contexto teórico (de 32k, 128k o incluso 256k tokens), ya que Ollama lo limita artificialmente.

Me pregunté por qué OpenCode no funcionaba en mi ordenador, aun cuando utilizaba varios modelos locales, y decidí investigar el asunto.

Ahora entiendo por qué al principio no tuve éxito, y por qué el sistema LLM no funcionaba del modo que esperaba. Estuve a punto de rendirme, pero finalmente he encontrado la solución.

## Comprender y configurar la ventana de contexto

El contexto se controla a través del parámetro `num_ctx`. Con una simple orden, se puede verificar qué valor está activo en ese momento.

```bash
ollama ps
```

La publicación muestra claramente el problema.

```bash
NAME                ID              SIZE      PROCESSOR    CONTEXT    UNTIL
qwen2.5-coder:7b    dae161e27b0e    4.9 GB    100% GPU     4096       4 minutes from now
```

A pesar de contar con hardware de alta potencia y un modelo que, en teoría, podría procesar mucho más datos, solo están disponibles 4096 tokens.

## Solución 1: El contexto global a través de systemd

La solución más elegante para lograr una configuración consistente es establecer una variable de entorno a nivel del sistema. De esta manera, todos los modelos se cargarán automáticamente con el contexto deseado.

```bash
sudo systemctl edit ollama.service
```

De forma alternativa, se puede editar directamente el archivo de sobrescritura (override file).

```bash
sudo nvim /etc/systemd/system/ollama.service.d/override.conf
```

El siguiente registro aumenta el contexto estándar a 16384 tokens:

```bash
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_CONTEXT_LENGTH=16384"
```

Tras volver a cargar, el cambio se activa.

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

La verificación con otro modelo demuestra el éxito.

```bash
NAME               ID              SIZE     PROCESSOR    CONTEXT    UNTIL
qwen3-coder:30b    06c1097efce0    20 GB    100% GPU     16384      4 minutes from now
```

## Solución 2: Ajuste manual del contexto en el chat

Para pruebas o uso ocasional, el contexto también se puede establecer directamente en el chat de Ollama.

```bash
ollama run qwen3:32b
```

En el chat:
```bash
/set parameter num_ctx 12288
```

**Sugerencia:** Con el comando ``/save qwen3-12k:32b``, incluso es posible guardar una nueva variante del modelo utilizando ese contexto. La próxima vez que se utilice ``ollama list``, dicha nueva variante estará disponible.

## Solución 3: Archivos de modelo: el método profesional

La solución más sostenible son los archivos de configuración (model files). Su creación solo requiere unos segundos, no ocupan casi espacio en el disco y documentan perfectamente la configuración del sistema.

Archivo de modelo de ejemplo para Ministral-3 con un contexto de 64k:

```Modelfile
FROM ministral-3:14b
PARAMETER num_ctx 65536
```

Crear:

```bash
ollama create ministral-3-64k:14b -f ministral-3-64k-14b.Modelfile
```

El resultado:

```bash
NAME                   ID              SIZE     PROCESSOR    CONTEXT    UNTIL
ministral-3-64k:14b    e1befb46cf0d    20 GB    100% GPU     65536      4 minutes from now
```

## Límites del hardware: ¿Qué es posible con una RTX 4090?

Un contexto más amplio no representa una posibilidad ilimitada, sino que está determinado por el presupuesto de hardware disponible. Es la GPU la que decide qué opciones son realmente viables y utilizables.

En mis pruebas con una RTX 4090 (24 GB de RAM), se obtuvieron los siguientes valores óptimos:

| Modelo | Contexto más relevante | Contexto Máximo | Uso de la VRAM |
|--------|-------------------|-------------------|--------------|
| qwen2.5-coder:7b | 32k | 32k | 8,2 GB |
| ministral-3:14b | 64k | 256k | 20 GB |
| qwen3-coder:30b | 32k | 256k | 22 GB |
| deepseek-r1:32b | 10k | 128k | 22 GB |
| GPT-OSS:20B | 128k | 128k | 17 GB |

Un valor demasiado alto para `num_ctx` conduce a lo siguiente:

- Errores por falta de memoria.
- Respuestas extremadamente lentas.
- Función de llamada a herramientas inestables (Instable Tool Calling).
- Uso compartido de la CPU y la GPU en lugar de utilizar únicamente la GPU.

Ejemplo de un modelo sobrecargado:

```bash
NAME         ID              SIZE     PROCESSOR          CONTEXT    UNTIL
qwen3:32b    030ee887880f    29 GB    22%/78% CPU/GPU    32768      4 minutes from now
```

La proporción de uso de la CPU indica que la GPU está sobrecargada; como resultado, se observan reducciones en el rendimiento.

## ¿Qué modelos funcionan con OpenCode?

Tras realizar pruebas exhaustivas, se ha determinado que tres modelos son especialmente adecuados.

### qwen3-coder:30b – El especialista en programación

Con una ventana de contexto de 32k, este modelo funciona de manera óptima en la RTX 4090. El uso de las herramientas es fiable y la velocidad es impresionante. El resultado se acerca mucho a la sensación que ofrece Claude Code aunque Claude sigue siendo, por supuesto, un caso aparte.

### devstral-small-2:24b: Un modelo versátil y de calidad

Basándose en un modelo predefinido, este programa crea archivos y los modifica según las especificaciones proporcionadas. Ocasionalmente se producen pequeños errores en el manejo del contexto (context handling), pero en general ofrece un rendimiento estable, incluso con hasta 32k elementos de contexto (contexts).

### GPT-OSS:20B – El campeón de análisis

El verdadero punto destacado: una capacidad de análisis del contexto de 128k sin que se reduzca el rendimiento del sistema. Perfecto para revisiones de código, análisis de documentación y proyectos de gran envergadura. Incluso si las llamadas a los herramientas fallan, el modelo se corrige automáticamente.

El único inconveniente es que las tablas creadas con Markdown no se renderizaban de manera óptima en OpenCode; sin embargo, ya he encontrado una solución para este problema: [Este plugin](https://github.com/franlol/opencode-md-table-formatter).

### qwen2.5-coder:7b – No se recomienda

A pesar de contar con un contexto de 32k, el modelo es demasiado simplificado (con solo 7 mil millones de parámetros) para ser utilizado como una herramienta fiable para la generación de código en OpenCode.

## Recomendación práctica para los usuarios de la RTX 4090

Mi recomendación actual, basada en mis propios ensayos, recae en estos modelos:

| Caso de Uso | Modelo | Contexto |
|----------|--------|---------|
| Programación/Herramientas | Qwen3-Coder-30B | 16–32k |
| Revisión/Análisis | GPT-OSS-20B | 64–128k |
| Documentos extensos / Conocimientos | Ministral-14B | 32–64k |

## Gestión de archivos de modelo: La organización lo es todo

Tiene su recompensa contar con un directorio dedicado específicamente a los archivos de modelo.

```bash
/mnt/sumpf/ai/opencode/ollama/modelfiles/
├── gpt-oss-64k-20b.Modelfile
├── gpt-oss-128k-20b.Modelfile
└── ministral-3-64k-14b.Modelfile
```

Por lo tanto, sigue siendo comprensible por qué se configuró un modelo de determinada manera, incluso después de varios meses.

## Mantenimiento y actualizaciones

Durante las actualizaciones del sistema en Arch Linux, los cambios realizados en el archivo `override.conf` se mantienen automáticamente. En caso de modificaciones manuales, basta con asegurarse de que estas se hayan aplicado correctamente.

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## Conclusión: el contexto no es una característica, sino un presupuesto

La «Ventana de Contexto» (Context Window) es ese elemento invisible que representa el «cuello de la botella» en muchos sistemas de tipo Ollama. Quienes deseen utilizar herramientas como OpenCode o similares deben modificar obligatoriamente el valor predeterminado de 4096 tokens.

Los tres métodos para resolver este problema —las variables de entorno a nivel global, los comandos de chat o los archivos de modelo— ofrecen la flexibilidad adecuada para cada escenario. Lo esencial es comprender que un contexto más amplio no constituye una característica ilimitada, sino que debe siempre considerarse en función del hardware disponible.

Con las configuraciones adecuadas, Ollama se convierte en una potente infraestructura de IA local capaz de respaldar de manera fiable incluso flujos de trabajo complejos.

Ahora también puedo permitir que uno de los modelos de lenguaje largo mencionados (LLM) acceda a mi wiki local, para que lo complete con información contextual que pueda ser procesada directamente. Es realmente asombroso lo que se puede hacer hoy en día. Aprendo algo nuevo cada día, y me divierte mucho.

¿Qué experiencias has tenido con Ollama y OpenCode? ¿Cuál de estos modelos funciona mejor para ti? No dudes en escribirme tus recomendaciones y consejos de configuración en los comentarios; estoy muy interesado en tu opinión.

{{< chat ollama-context >}}
