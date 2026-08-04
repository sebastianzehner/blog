+++
title = 'De Ollama a llama.cpp: Más control con llama-swap'
description = 'Por qué cambié de Ollama a llama.cpp: más control, 128k de contexto con Qwen3.6 27B y gestión de VRAM con llama-swap en una RTX 4090.'
summary = 'Ollama fue mi estándar para LLMs locales durante mucho tiempo. llama.cpp con llama-swap ofrece más control y devuelve la gestión automática de VRAM.'
date = 2026-08-04T17:30:00-03:00
lastmod = 2026-08-04T17:30:00-03:00

tags = ['llm', 'ai', 'open-source', 'linux', 'terminal']
categories = ['TechLab']

[params]
showComments = true
chatId = 'ollama-to-llama-cpp'

[translation]
  tool = 'Pi Agent - Qwen3.6-27B'
  version = '0.83.0'
  from = 'de'
  to = 'es'
  date = 2026-08-04T17:30:00-03:00
+++

Durante mucho tiempo, Ollama fue mi estándar para Large Language Models locales. La instalación era sencilla, el uso era intuitivo, y los modelos se cargaban con un solo comando. Pero cuantos más LLMs locales utilicé, más evidentes se volvieron las limitaciones.

Me despidí de Ollama y cambié a [llama.cpp][1] con el proxy [llama-swap][2] por delante. El resultado: **control total sobre VRAM, contexto y comportamiento del modelo**, y la memoria de la GPU se libera automáticamente cuando la necesito para ComfyUI.

## Por qué Ollama ya no bastaba

Ollama es una gran herramienta para empezar. Se encarga automáticamente del tamaño del modelo, la ventana de contexto y el uso de hardware, lo cual es perfecto para chats sencillos. Mi configuración se veía así durante mucho tiempo, como describí en mi artículo anterior sobre [Optimización de la Ventana de Contexto de Ollama][3]: Ollama como servicio systemd con un `OLLAMA_CONTEXT_LENGTH` fijo y archivos de modelo para diferentes valores de `num_ctx`.

En aquel momento todavía usaba OpenCode como agente, y desde entonces me he cambiado a Pi — más sobre eso en otro artículo. El desarrollo en el ámbito de la IA simplemente va a gran velocidad; apenas se documenta una configuración y ya hay algo nuevo en el horizonte.

Tres razones finalmente me empujaron a cambiar.

### Control sobre plantillas de chat y metadatos del modelo

Ollama ya puede cargar modelos GGUF arbitrarios directamente desde Hugging Face, no solo desde su propia biblioteca — así que no estás fundamentalmente encerrado. El problema es más profundo: Ollama traduce internamente las plantillas de chat a su propia sintaxis Go template, en lugar de usar las plantillas Jinja incrustadas en el archivo GGUF. Para modelos nuevos o inusuales, esto conduce repetidamente a incompatibilidades que hay que depurar antes de que el modelo siquiera responda correctamente.

El servidor llama.cpp trabaja directamente con archivos GGUF y lee sus plantillas Jinja de forma nativa. Descargas el modelo deseado desde Hugging Face u otra fuente, lo colocas en la carpeta y ya está. Sin paso de traducción, sin adivinar si la plantilla se reconoció correctamente. Esta es una diferencia enorme cuando se trabaja con modelos nuevos o exóticos.

### Rendimiento y soporte de modelos desde el primer día

Además de los problemas de compatibilidad, está el rendimiento puro. Ollama tiene sobrecarga. [Benchmarks de la comunidad][4] muestran que llama.cpp corre 1,5 a 1,8 veces más rápido en el mismo hardware. Esto se hizo especialmente claro con la introducción de gpt-oss-20b: Porque Ollama hizo un fork del kernel de inferencia ggml para un rápido soporte desde el primer día sin coordinarse con el upstream de llama.cpp, se midió [inferencia entre 20 y 30 por ciento más lenta][5] en aquel momento. Para un sistema que trabaja con grandes ventanas de contexto y consultas complejas, una diferencia así se nota rápidamente.

Además, está el tema general del soporte de modelos: los nuevos GGUF suelen aparecer en Hugging Face dentro de horas después de un lanzamiento. Con Ollama hay que esperar a que alguien empaquete el modelo para el registro. Quien quiera estar en la vanguardia puede empezar inmediatamente con llama.cpp.

### Control total sobre cuantización y el motor de inferencia

Ollama es una capa sobre llama.cpp — cómoda, pero cada configuración pasa por un filtro. Se nota primero con la cuantización: Ollama ofrece solo un puñado de niveles, mientras que en Hugging Face se dispone del rango completo desde IQ2 hasta BF16. Dependiendo del modelo y el hardware, esta elección puede marcar una gran diferencia, tanto en calidad como en consumo de VRAM.

El filtro también se muestra en otras configuraciones. El servidor llama.cpp da acceso directo a cosas como el tipo de caché KV (por ejemplo, `--cache-type-k q4_0` para grandes ventanas de contexto), transferencia precisa de capas a la GPU, o inferencia en modo dividido. Ollama oculta esta complejidad deliberadamente. Esto es práctico para principiantes, pero para configuraciones avanzadas eventualmente se convierte en un problema porque no se puede llegar a la configuración exacta que se necesita.

## llama.cpp: Controlando el motor directamente

El servidor de [llama.cpp][1] es el motor de inferencia bajo el capó. Escrito en C/C++, lee modelos GGUF y ofrece control total sobre cada aspecto de la inferencia. Lo instalo mediante el paquete AUR `llama.cpp-cuda`, que incluye soporte CUDA para la RTX 4090:

```bash
cd ~/builds
git clone https://aur.archlinux.org/llama.cpp-cuda.git
cd llama.cpp-cuda
makepkg
sudo pacman -U llama.cpp-cuda-*.pkg.tar.zst
```

También existe `llama.cpp-cuda-git`, que siempre compila contra el estado más reciente del repositorio. Uso deliberadamente la variante más estable `llama.cpp-cuda` y solo actualizo manualmente cuando quiero probar un modelo nuevo y no funciona con mi versión actual. Para Qwen3.6 27B, recientemente fue necesaria una actualización así. Hasta ahora no he tenido problemas con este enfoque.

El paquete instala `llama-server` y todas las herramientas asociadas en `/usr/bin/`. Esto me da acceso directo a parámetros como:

- `-ngl 99` — cargar todas las capas en el VRAM
- `--ctx-size 131072` — ventana de contexto explícita de 128k
- `--cache-type-k q4_0` — cuantización del caché KV para contextos grandes
- `--mmproj` — proyector multimodal para entradas de imagen
- `--spec-type draft-mtp` — decodificación especulativa con predicción de múltiples tokens

Este es un control que Ollama no me ofrece en esta forma.

## llama-swap: Recuperando la comodidad de Ollama

Lamentablemente, llama.cpp por sí solo tiene un inconveniente: no admite la descarga automática. Un modelo cargado permanece cargado hasta que detienes el servidor manualmente. Aquí entra en escena [llama-swap][2].

llama-swap es un proxy que se coloca delante del llama-server y carga automáticamente el modelo configurado en la primera solicitud. Después de un periodo de inactividad configurable — yo uso 300 segundos — se detiene `llama-server` y el VRAM se libera por completo. Este es exactamente el comportamiento que me faltaba en llama.cpp y al que estaba acostumbrado de Ollama.

Instalación también por AUR:

```bash
cd ~/builds
git clone https://aur.archlinux.org/llama-swap.git
cd llama-swap
makepkg
sudo pacman -U llama-swap-*.pkg.tar.zst
```

El servicio funciona como unidad systemd. Para que se inicie automáticamente al arrancar, lo activo:

```bash
sudo systemctl enable --now llama-swap
```

El servicio escucha en `127.0.0.1:12434`, la configuración reside en `/etc/llama-swap/config.yaml` y soporta múltiples modelos simultáneamente.

Una piedra en el camino: el paquete establece `DynamicUser=yes` de forma predeterminada. Esto significa que el servicio se ejecuta con su propio usuario aislado que no tiene acceso a mi unidad NVMe interna montada en `/mnt/sumpf/` — que es exactamente donde están mis modelos. Un override de systemd lo soluciona sin modificar el archivo del paquete en sí:

```bash
sudo systemctl edit llama-swap
```

```ini
[Service]
DynamicUser=no
User=<username>
```

### La configuración

```yaml
healthCheckTimeout: 120
logLevel: info
logToStdout: proxy
globalTTL: 300

macros:
  models_dir: "/mnt/sumpf/ai/ComfyUI/models/LLM"

models:
  gemma-4-26B-A4B-it:
    cmd: >
      llama-server --port ${PORT}
      -m ${models_dir}/gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf
      --mmproj ${models_dir}/mmproj-gemma4-BF16.gguf
      -ngl 99 --ctx-size 131072
    name: "Gemma 4 26B (llama.cpp)"
    ttl: 300
  qwen3.6-27B:
    cmd: >
      llama-server --port ${PORT}
      -m ${models_dir}/Qwen3.6-27B-UD-Q4_K_XL.gguf
      --mmproj ${models_dir}/mmproj-qwen36-BF16.gguf
      --spec-type draft-mtp --spec-draft-n-max 2 -np 1
      -ngl 99 --ctx-size 131072
      --cache-type-k q4_0 --cache-type-v q4_0
    name: "Qwen 3.6 27B (llama.cpp)"
    ttl: 300
```

Detalles importantes:

- **`DynamicUser=no`** — Como necesito acceder a `/mnt/sumpf/`, el servicio corre bajo mi usuario (configurado mediante `sudo systemctl edit llama-swap`)
- **`-ngl 99`** — Todas las capas en el VRAM, sin división CPU/GPU
- **`--ctx-size 131072`** — Establecido explícitamente, en lugar de aceptar el valor calculado automáticamente
- **`--cache-type-k q4_0`** — Cuantización del caché KV, necesaria para 128k de contexto sin errores de memoria insuficiente

Un breve contexto sobre el valor de `--ctx-size`: Sin esta configuración explícita, `llama-server` ha estado reduciendo automáticamente el contexto desde la función integrada de [ajuste automático][6] para mantener un búfer de VRAM de 1 GB (valor predeterminado de `--fit-target`). En mi sistema eso cayó en 196608 en lugar de los 262144 tokens completos que Qwen3.6-27B soporta nativamente. Incluso eso todavía estaba demasiado justo en mi VRAM, así que bajé manualmente a 131072 — el compromiso más estable entre tamaño de contexto y búfer de VRAM para mi hardware.

## El modelo: Qwen3.6 27B

Después de pruebas extensivas con varios modelos (más recientemente Gemma 4 26B), me decidí por Qwen3.6 27B. Descargado de Unsloth en formato GGUF, cuantización `UD-Q4_K_XL`. Con 24 GB de VRAM no hay razón para sacrificar calidad de cuantización.

El modelo trae tres características que corren simultáneamente en la RTX 4090:

1. **Ventana de contexto de 128k** — suficiente para flujos de trabajo agénticos complejos y bases de código grandes
2. **Multimodal / Visión** — las imágenes pueden procesarse como entrada mediante el proyector `mmproj` (`mmproj-qwen36-BF16.gguf`)
3. **Predicción de múltiples tokens (MTP)** — decodificación especulativa que acelera la inferencia aproximadamente entre 1,5 y 2×

Rendimiento medido con esta configuración:

| Métrica | Valor |
|---|---|
| Tokens por segundo (generación) | ~82 t/s |
| Tokens por segundo (eval. de prompt) | ~116 t/s |
| Tasa de aceptación de borrador (MTP) | ~75 % |
| Uso de VRAM | ~21 GB de 24 GB |

Para respuestas estructuradas — como llamadas a herramientas o generación de código — la tasa de aceptación MTP supera el 80 %. Eso significa: más tokens por paso, tiempos de respuesta más rápidos.

## Integración con Pi

Mi agente Pi se conecta a través del extremo de llama-swap. La configuración en `~/.pi/agent/models.json` muestra cómo se integra la API compatible con OpenAI:

```json
{
  "providers": {
    "llama-cpp": {
      "baseUrl": "http://127.0.0.1:12434/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "gemma-4-26B-A4B-it",
          "name": "Gemma 4 26B (llama.cpp)",
          "input": ["text", "image"],
          "contextWindow": 131072
        },
        {
          "id": "qwen3.6-27B",
          "name": "Qwen 3.6 27B (llama.cpp)",
          "input": ["text", "image"],
          "contextWindow": 131072
        }
      ]
    }
  }
}
```

Como llama-swap proporciona una API compatible con OpenAI, cualquier aplicación que hable interfaces OpenAI funciona — sin cambios en el lado del cliente.

## VRAM bajo demanda: llama.cpp cede el paso a ComfyUI

Esta es la característica que hace que el cambio valga la pena para mí. llama.cpp por sí solo no libera el VRAM, pero con llama-swap por delante eso funciona de nuevo automáticamente. El modelo se carga bajo demanda, y 300 segundos después de la última solicitud, el VRAM está completamente libre para ComfyUI.

Si necesito liberarlo de inmediato — por ejemplo antes de una sesión grande de ComfyUI — basta con un solo comando:

```bash
curl -X POST http://127.0.0.1:12434/api/models/unload
```

llama-swap permanece activo y recarga automáticamente el modelo en la siguiente solicitud, completamente sin un `systemctl restart` manual.

## Monitoreo y depuración

El estado de llama-swap se puede rastrear cómodamente con `journalctl`:

```bash
journalctl -fu llama-swap
```

Las entradas de registro más importantes:

- **`Health check passed`** — llama-server iniciado correctamente, la primera solicitud tarda ~6 segundos
- **`200`** — solicitud exitosa, solicitudes posteriores significativamente más rápidas (~400ms–2s)
- **`Unloading model, TTL of 300s reached`** — se está liberando el VRAM
- **`Configuration Changed / Reloaded`** — los cambios en `config.yaml` se detectan automáticamente gracias a `-watch-config` (activado de forma predeterminada en el paquete AUR)

Además, hay una interfaz web en `http://127.0.0.1:12434` que redirige automáticamente a `http://127.0.0.1:12434/ui/`. Allí encontrarás un playground, una lista de modelos configurados con registros upstream, estadísticas de actividad y registros tanto para proxy como para upstream.

## Lecciones aprendidas: Ollama fue el punto de partida correcto

Y con sinceridad, tampoco extraño nada esencial al respecto. Todavía recomiendo Ollama para cualquiera que quiera poner un LLM local funcionando rápido sin lidiar con parámetros.

Pero una vez que profundizas — gestionando múltiples modelos, optimizando VRAM, o necesitando parámetros de inferencia específicos — la capa de abstracción se convierte en un cuello de botella. llama.cpp con llama-swap por delante me da todo lo que Ollama ofrecía (carga/descarga automática, API OpenAI), más el control que realmente necesito.

El cambio cuesta aproximadamente una hora de configuración. El paquete AUR se encarga de la mayor parte del trabajo, y el `config.yaml` es autoexplicativo.

## Conclusión

El cambio de Ollama a llama.cpp con llama-swap fue el paso correcto. Tengo más control sobre el contexto, la cuantización y la gestión del VRAM. Mi sistema ahora puede cambiar sin problemas entre LLM de texto y ComfyUI sin que tenga que intervenir manualmente.

Qwen3.6 27B con 128k de contexto, soporte de visión y aceleración MTP funciona de forma estable en la RTX 4090. Con ~82 tokens por segundo de generación y ~75 % de tasa de aceptación de borrador, el rendimiento es impresionante para hardware local.

Si tú también cambias de Ollama a llama.cpp: empieza con el paquete AUR, configura llama-swap con un modelo a tu elección, y ajusta el `config.yaml` según necesites. El esfuerzo vale la pena.

Un saludo,  
Sebastian

[1]: https://github.com/ggml-org/llama.cpp
[2]: https://github.com/mostlygeek/llama-swap
[3]: ollama-context-window-optimization-opencode/
[4]: https://willschenk.com/howto/2026/migrating_to_llama_cpp/
[5]: https://www.nijho.lt/post/llama-nixos/
[6]: https://github.com/ggml-org/llama.cpp/discussions/18049

{{< translation-note >}}
