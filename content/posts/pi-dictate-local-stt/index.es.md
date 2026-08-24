+++
title = 'Pi Dictate: Dictado de voz local con Sherpa-ONNX en la terminal'
description = 'Pi Dictate en su fork: dictado de voz local para el Pi Agent con Sherpa-ONNX, sin nube y sin API key. Setup, atajos de teclado y problemas del uso real diario.'
summary = 'pi-dictate en su fork: habla en local y el texto aparece casi al instante en el campo de entrada del Pi Agent. Sherpa-ONNX como backend STT, sin nube.'
date = 2026-08-24T17:00:00-03:00
lastmod = 2026-08-24T17:00:00-03:00

tags = ['ai', 'stt', 'llm', 'qwen', 'terminal', 'open-source']
categories = ['TechLab']

[params]
showComments = true
chatId = 'pi-dictate'

[translation]
  tool = 'Pi Agent - Qwen3.8-27B'
  version = '0.84.3'
  from = 'de'
  to = 'es'
  date = 2026-08-24T18:30:00-03:00
+++

Presiono `ctrl+shift+m`, hablo al micrófono, vuelvo a presionar `ctrl+shift+m`, y la frase ya está en el campo de
entrada del Pi Agent. Sin rodeo por la nube, sin API key y sin retraso perceptible. Suena a feature de un video
publicitario, pero en mi caso es el workflow normal desde esta semana.

El que lo hace posible es [pi-dictate][1], una extensión mínima de Pi para el dictado de voz en la terminal, que
forké y cambié a STT completamente local. Como backend corre un servidor de [Sherpa-ONNX][2] en mi Mac Studio; el
audio viaja por WebSocket a través del LAN, y el texto transcribido vuelve poco después a la ventana de chat.

{{< github repo="sebastianzehner/pi-dictate" showThumbnail=true >}}

## Por qué forké pi-dictate

[El original de amosblomqvist][3] es un proyecto minimalista bien pensado: sin ventana de dictado flotante, sin app de
barra de menús, sin notificaciones. Presionar `alt+m`, hablar, presionar `alt+m` de nuevo, y el texto aterriza en el
campo de entrada enfocado. Sea el editor de chat, un popup o un diálogo: la tecla se intercepta a nivel TUI, antes de
que el componente enfocado la vea.

Dos cosas no me cuadraban. Primero el backend: el original streama el audio a Deepgram Nova-3, un servicio en la nube
con API key y un coste de unos 0,50 USD por hora de habla. Segundo, la plataforma: el original está pensado para macOS
(`pbcopy` para el fallback del portapapeles, `sox` para la captura), y yo trabajo en Arch Linux con dwm.

El fork reemplaza el backend por completo con un servidor local de Sherpa-ONNX. Sin doble configuración, sin segundo
camino de código: es simplemente otro WebSocket al otro lado. Todo lo que hace especial al original se conserva:
medidor de nivel, detección de foco, entrega al campo de entrada correcto. Solo cambió el lado con el que habla el
audio.

## Cómo funciona el dictado

Primero enfoco un campo de entrada, ya sea la ventana de chat principal, el campo de notas de un quiz o el campo de
respuesta de `ask_user_question`. `ctrl+shift+m` inicia la grabación; la línea de estado muestra un punto rojo más un
medidor de nivel que se mueve con mi voz: `● ▁▂▃▅ listening…`. Si nada está enfocado, el dictado ni siquiera empieza, y
una notificación explica por qué.

Hablar, y el segundo `ctrl+shift+m` detiene todo. Un breve spinner de `finalizing…`, normalmente demasiado rápido para
verlo en un servidor local, y luego el texto está ahí. La transcripción va en vivo: el servidor entrega texto
continuamente mientras hablas, pero solo se inserta en un único paso al detener. `ctrl+shift+n` interrumpe un dictado
en curso y descarta la transcripción, seguro de presionar en cualquier momento.

Lo importante es el destino del texto: siempre se **anexa, nunca se reemplaza**, y va al campo que está
**enfocado en el momento de detener**.

Eso permite, por ejemplo, el siguiente flujo: empezar un dictado, pegar después un mensaje de error desde la
terminal, iniciar otro dictado, y el texto nuevo se anexa simplemente en vez de sobrescribir algo. Al final se puede
enviar todo junto en el chat.

En concreto, el anexo funciona así según el contexto:

- Editor o campo de entrada de popup: anexo directo
- Diálogos cerrados (quiz, `ask_user_question`): como pulsaciones sintéticas, así que primero cambia al campo de
  notas con Tab
- Ningún campo de entrada enfocado: portapapeles vía `xclip`, más una notificación

Opcionalmente se puede activar la vista previa en vivo (`LIVE_PREVIEW = true` en `index.ts`). Entonces la línea de
estado muestra junto al medidor de nivel también el texto rodante, el mejor feedback si quieres ver qué está
entendiendo el servidor.

## El servidor STT: Sherpa-ONNX con el modelo Kroko

La pieza central es un contenedor Docker ligero con el servidor WebSocket de Sherpa-ONNX en el puerto 6006. Como
modelo uso el Zipformer streaming alemán [de-kroko-2025-08-06][4]. En mi setup la latencia está por debajo de 300ms,
el texto aparece prácticamente al mismo tiempo que hablas, y la carga de CPU en el Mac Studio se mantiene baja.

El modelo tiene una segunda ventaja: puntúa y capitaliza nativamente. Comas, puntos, signos de interrogación y de
exclamación vienen directamente del modelo, sin paso de post-procesado tipo `smart_format`. Las palabras en inglés y
los términos técnicos también se reconocen con fiabilidad y se escriben correctamente, sin cambiar el idioma
manualmente. Si quieres dictar en otros idiomas, solo hay que sustituirlo por otro modelo sherpa-onnx en el servidor.

El protocolo es simple: 16 kHz de PCM mono suben como frames binarios de WebSocket, y de vuelta llega JSON con un
texto rodante que se reemplaza a sí mismo en cada update. Después del string `DONE` llega exactamente un final. Un
detalle que conviene conocer si construyes tus propios clients: el servidor no cierra la conexión después del final
por sí mismo; el cliente debe hacerse cargo. Quien se lo olvida deja la sesión abierta en el servidor. Esto aplica a
cualquier cliente que se conecte a este servidor: mi asistente de voz Konrad cuelga de esa misma instancia, con su
proxy Wyoming.

## Instalación

En el lado de Pi, el setup es corto:

```bash
pi install git:github.com/sebastianzehner/pi-dictate
pacman -S pulseaudio-utils xclip
```

`pulseaudio-utils` proporciona `parec` para la captura nativa a 48 kHz, `xclip` el fallback del portapapeles. La
extensión remuestrea internamente por filtro FIR a 16 kHz mono, el formato que el servidor espera. El servidor STT se
inicia aparte con Docker Compose:

```bash
docker compose -f <ruta-al-compose-de-sherpa>/compose.yaml up -d
```

Dos variables de entorno controlan la extensión, leídas al cargar Pi:

| Variable          | Default                    | Efecto                                               |
| ----------------- | -------------------------- | ---------------------------------------------------- |
| `DICTATE_STT_URL` | `ws://mac-studio.lan:6006` | URL WebSocket del servidor Sherpa-ONNX               |
| `DICTATE_DEBUG`   | off                        | `1` registra eventos WebSocket en `/tmp/dictate-debug.log` |

Tras la instalación o después de cambios en `index.ts`, basta con un `/reload` en Pi.

## Problemas

Tres puntos me costaron tiempo en el setup, que me gustaría ahorrarte:

1. **Atajos y terminales.** `ctrl+shift+m` no es representable como byte legacy; el terminal debe emitir CSI-u
   (protocolo Kitty). En st adapté `mappedkeys[]` en `config.h` en consecuencia, y en tmux 3.5+ activo
   `extended-keys on` y `extended-keys-format csi-u`. La documentación de Pi sobre el setup de tmux lo explica en
   detalle: [pi.dev/docs/latest/tmux][5].
2. **Colisión con dwm.** El original eligió deliberadamente `alt+m`/`alt+n`, porque los binds `ctrl+shift` no son
   distinguibles de Enter en terminales sin soporte CSI-u. Los binds alt colisionaban con mis shortcuts de dwm, de ahí
   el cambio a `ctrl+shift` combinado con salida CSI-u moderna.
3. **Wayland.** Aún no soportado. `xclip` necesita X11; un fallback con `wl-copy` tendría que añadirse si a alguien le
   interesa.

## Y Pi sigue siendo lo que es

Una frase que quizá sorprenda: simplemente sigo amando al Pi Agent. La entrada por voz no hace redundante el
teclado, pero hablar prompts largos y descripciones detalladas es más rápido y más relajante que teclear. El dictado va
directo a la ventana de chat donde el agente ya me espera.

Por cierto, el stack de LLM bajo Pi no ha cambiado: llama.cpp con llama-swap como proxy, como en mi [artículo sobre el
cambio desde Ollama][6]. Solo cambió el modelo. En lugar de Qwen3.6-27B ahora corre Qwen3.8-27B en formato
`UD-Q4_K_XL`, con proyector de visión y predicción multi-token como antes. En la configuración de llama-swap es un
camino de modelo simplemente cambiado, y gracias al TTL la VRAM se libera automáticamente como antes en cuanto la
necesito para ComfyUI.

Esta extensión, el fork con la integración de dictado, por cierto nació ella misma con el Pi Agent, sobre mi
hardware local bajo Qwen3.8. De verdad que ya se puede dejar que tus herramientas construyan tus herramientas.

## Conclusión

El STT local es definitivamente práctico para el dictado de voz: menos de 300ms de latencia, puntuación nativa, sin
costes de API recurrentes, y ningún dato de audio sale del LAN. El fork se mantiene tan ligero como el original, un
solo archivo TypeScript, con licencia MIT, y está en uso diario desde esta semana. Si usas Pi y prefieres dictar a
teclear: la prueba vale la pena.

Un saludo,  
Sebastian

[1]: https://github.com/sebastianzehner/pi-dictate
[2]: https://github.com/k2-fsa/sherpa-onnx
[3]: https://github.com/amosblomqvist/pi-dictate
[4]: https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-de-kroko-2025-08-06
[5]: https://pi.dev/docs/latest/tmux
[6]: switching-from-ollama-to-llama-cpp/

{{< translation-note >}}
