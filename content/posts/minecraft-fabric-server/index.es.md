+++
title = 'Configurando un Servidor Fabric de Minecraft en Casa: Guía Paso a Paso'
description = 'Guía paso a paso para configurar un servidor de Minecraft modificado con Fabric en Linux. Desde la instalación hasta la selección de mods y su funcionamiento en la red local.'
summary = 'PaperMC es bueno para plugins, pero para mods de verdad necesitas Fabric. Aquí te muestro cómo configurar un servidor de Minecraft modificado en Linux con más de 20 mods para agricultura, decoración y rendimiento.'
date = 2026-07-29T12:00:00-03:00
lastmod = 2026-07-29T12:00:00-03:00

tags = ['minecraft', 'linux', 'bash', 'self-hosting', 'open-source', 'terminal']
categories = ['TechLab']

showComments = true
chatId = "minecraft-fabric-server"

[translation]
  tool = 'Pi Agent - Qwen3.6-27B'
  version = '0.83.0'
  from = 'de'
  to = 'es'
  date = 2026-07-30T10:48:34-03:00
+++

Tienes un servidor de Minecraft funcionando en casa — todo funciona, Vanilla
pura, quizás algunos plugins de Paper. Pero ahora quieres más: nuevos biomas,
mods de cocina, elementos decorativos, modding de verdad. El problema: **PaperMC
y los mods de Fabric no son compatibles.** Paper no entiende mods del lado del
servidor con nuevos objetos, bloques o mecánicas.

La solución es un **servidor Fabric** paralelo — completamente separado de tu
instalación de Paper, con su propio cargador de mods y su propio mundo
modificado. En este artículo te mostraré cómo configuré mi servidor Fabric
"Sumpfland" en Linux, qué mods instalé y en qué debes fijarte durante su
funcionamiento.

## ¿Por qué un segundo servidor?

En mi configuración ya tengo un servidor PaperMC para plugins Vanilla. Los mods
de Fabric requieren el cargador de Fabric — el cual es incompatible con Paper.
Así que opté por un segundo servidor paralelo:

| Característica   | Servidor PaperMC                 | Servidor Fabric                           |
| ---------------- | -------------------------------- | ----------------------------------------- |
| Enfoque          | Plugins (compatible con vanilla) | Mods (nuevos bloques, objetos, mecánicas) |
| Cargador de mods | Ninguno (Paper)                  | Cargador de Fabric                        |
| Directorio       | `~/minecraft/server/`            | `~/minecraft/fabric-server/`              |

Ambos servidores funcionan en el mismo equipo — un ThinkCentre M715q Gen. 2 —
pero en directorios completamente separados. Sin riesgo de que uno afecte al
otro.

> **Mods vs. Add-ons:** Los mods solo están disponibles para la **Java
> Edition**. La Bedrock Edition usa add-ons, que son significativamente más
> limitados (basados en JSON/scripts). Este artículo se enfoca exclusivamente en
> la Java Edition con Fabric.

## Requisitos previos

Antes de empezar, necesitas:

- **Java 21** (para Minecraft 1.21.x) o **Java 25** (para Minecraft 26.x)
- Un equipo con Linux (el mío es un ThinkCentre, pero cualquier servidor sirve)
- Al menos **4 GB de RAM** para el servidor (para una lista de mods como esta,
  con más de 20 mods, planifica 6–8 GB)
- `tmux` para ejecución en segundo plano (opcional, pero recomendado)
- `curl` y `jq` (para descargar mods y mi script de actualización)

Comprueba e instala Java si es necesario:

```bash
java -version

# Si no está instalado:
sudo apt install openjdk-25-jre-headless
```

## Paso 1: Crear el directorio

Crea una carpeta dedicada para el servidor Fabric — completamente separada de
cualquier servidor Paper existente:

```bash
cd ~/minecraft
mkdir fabric-server
cd fabric-server
```

## Paso 2: Descargar el JAR del servidor Fabric

[Fabric](https://fabricmc.net/use/server/) proporciona una Meta API que te
permite descargar el JAR del servidor directamente — no se necesita instalador
separado. La URL sigue este patrón:

```
https://meta.fabricmc.net/v2/versions/loader/{version_minecraft}/{version_loader}/{version_installer}/server/jar
```

Para Minecraft 26.2 con Fabric Loader 0.19.3:

```bash
curl -OJ https://meta.fabricmc.net/v2/versions/loader/26.2/0.19.3/1.1.1/server/jar
```

El archivo descargado se llamará algo como `fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar`.

## Paso 3: Aceptar el EULA

Antes de que el servidor pueda iniciar, necesitas aceptar el Acuerdo de Licencia
de Usuario Final:

```bash
echo "eula=true" > eula.txt
```

## Paso 4: Instalar la API de Fabric

La [API de Fabric](https://modrinth.com/mod/fabric-api) es la base de casi todos
los mods de Fabric. Sin ella, la mayoría de las extensiones simplemente no
funcionarán.

```bash
mkdir -p mods
cd mods
curl -OJ "https://cdn.modrinth.com/data/P7dR8mSH/versions/Cpy2Px2f/fabric-api-0.154.0%2B26.2.jar?mr_download_reason=standalone&mr_game_version=26.2&mr_loader=fabric"
cd ..
```

> **Importante:** La URL contiene caracteres `&` — siempre envuélvela entre
> comillas, o la shell interrumpirá el comando. Si el nombre de archivo contiene
> caracteres codificados en URL (`%2B` en lugar de `+`), renómbralo:

```bash
mv "fabric-api-0.154.0%2B26.2.jar" "fabric-api-0.154.0+26.2.jar"
```

## Paso 5: Crear un script de inicio

Crea un archivo `start.sh` para iniciar el servidor de forma cómoda:

```bash
#! /bin/bash
java -Xmx4G -Xms2G -jar fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar nogui
```

Hazlo ejecutable:

```bash
chmod +x start.sh
```

Ajusta los valores de RAM (`-Xmx`, `-Xms`) a tu equipo. Con 4 GB máximo y 2 GB
de inicio, funcionó estable con todos los mods y cuatro jugadores — para una
lista de mods más grande o más jugadores simultáneos, planificaría 6 GB
(`-Xmx6G`).

## Paso 6: Iniciar el servidor en segundo plano con tmux

Para el funcionamiento a largo plazo recomiendo `tmux` — el servidor sigue
funcionando incluso cuando cierras la terminal:

```bash
tmux new -s fabric-server
cd ~/minecraft/fabric-server
./start.sh
```

Desconecta la sesión (`Ctrl+B`, luego `D`), reconecta con `tmux attach -t
fabric-server`, lista todas las sesiones con `tmux ls`. Detén el servidor
correctamente con el comando `/stop` en la consola.

## Configuración: server.properties

Al primer inicio, Fabric genera un archivo `server.properties` con valores
predeterminados. Los ajustes más importantes:

```properties
difficulty=normal
level-name=tu-mundo
max-players=6
motd=§2Tu Servidor §8| §fMinecraft Fabric §a❤
server-port=25566
```

Si ejecutas un servidor Paper en el mismo equipo, elige un puerto diferente (el
predeterminado es 25565). El MOTD admite códigos de color — `§2` es verde
oscuro, `§a` verde claro, `§f` blanco, `§l` negrita, `§o` cursiva.

### Otorgar permisos de operador

En un servidor Fabric nuevo, nadie tiene permisos de operador. En la consola del
servidor (tmux):

```bash
op tu-usuario
```

Repite para jugadores adicionales. Sin permisos de operador, comandos como
`/gamerule` o `/kick` no funcionarán en el chat del juego — sin embargo, los
comandos de administrador a través de la consola del servidor (tmux) siempre
funcionan independientemente del estado de operador.

### Icono del servidor

Un icono personalizado del servidor es un PNG de **exactamente 64×64 píxeles**,
guardado como `server-icon.png` en el directorio raíz (mismo nivel que
`eula.txt`). Reinicia el servidor después de copiarlo para que el icono
aparezca.

## Selección de mods: qué da vida al servidor

Ahora llega la parte divertida — los mods. Mi selección se enfoca en **juego
familiar**: agricultura, cocina, decoración, generación de mundo y rendimiento.
Sin mods agresivos de PvP o tecnología pesada.

Aquí están los destaques de mi lista de mods:

### Generación de mundo: Terralith

[Terralith](https://modrinth.com/mod/terralith) cambia fundamentalmente la
generación de mundo — más de 95 nuevos biomas, cañones, islas flotantes, fosas
oceánicas. Lo mejor: usa **exclusivamente bloques vanilla**. El inventario
permanece sin cambios, solo el paisaje se vuelve más diverso.

> **Importante:** Terralith **debe instalarse antes de la generación del
> mundo**. Agregarlo a un mundo existente corre el riesgo de errores en los
> límites de chunks y uniones de terreno. En nuestro caso, estuvo desde el
> principio.

Dado que Terralith no registra nuevos bloques ni objetos, solo necesita
instalarse en el **servidor** — el cliente técnicamente no sabe que Terralith
está funcionando. La dependencia adicional **Lithostitched** (mod de biblioteca
para configuración de generación de mundo) también es necesaria.

### Agricultura y cocina: Farmer's Delight + Rustic Delight + Ube's Delight

[Farmer's Delight](https://modrinth.com/mod/farmers-delight-refabricated) es el
corazón de la jugabilidad de agricultura: nuevos cultivos, electrodomésticos de
cocina, platos y un sistema de cocina dedicado. Construyendo sobre eso:

- **[Rustic Delight](https://modrinth.com/mod/rustic-delight)** — pancakes (6
  sabores), café, pimientos, algodón, calamar
- **[Ube's Delight](https://modrinth.com/mod/ubes-delight)** — inspirado en
  Filipinas: ube (batata morada), ajo, jengibre, ube milk tea, halo halo, y más

Los tres mods son aditivos — agregan nuevo contenido sin cambiar el juego base.
Los objetos vanilla mantienen su función original y ganan posibilidades de
recetas adicionales.

### Decoración: Beautify + Storage Delight + Too Many Paintings

Para construcciones visualmente atractivas:

- **[Beautify Refabricated](https://modrinth.com/mod/beautify-refabricated)** —
  macetas colgantes, persianas, marcos de fotos, nuevas fuentes de luz (faroles
  de bambú, candelabros), enredaderas, y más
- **[Storage Delight](https://modrinth.com/mod/storage-delight)** — cajones,
  estantes de libros con puertas, gabinetes de cristal, armarios de una puerta
- **[Too Many Paintings](https://modrinth.com/mod/too-many-paintings)** —
  significativamente más pinturas con una GUI de selección buscable

### Comodidad: Comforts + Sit Anywhere + JourneyMap

- **[Comforts](https://modrinth.com/mod/comforts)** — sacos de dormir y hamacas
  para saltarse ciclos día/noche
- **[Sit Anywhere!](https://modrinth.com/mod/sit-anywhere!)** — siéntate en casi
  cualquier bloque (escaleras, cercas) con clic derecho
- **[JourneyMap](https://modrinth.com/plugin/journeymap)** — minimapa en el
  juego más mapa web en el navegador (puerto 8080)

### Rendimiento: Lithium + Spark + Better Fabric Console

- **[Lithium](https://modrinth.com/mod/lithium)** — optimiza la lógica interna
  del servidor (IA de mobs, redstone, ticking del mundo) para mejor rendimiento
- **[Spark](https://modrinth.com/mod/spark)** — herramienta de perfilado para
  diagnosticar picos de lag y caídas de TPS
- **[Better Fabric Console](https://modrinth.com/mod/better-fabric-console)** —
  salida de registro con colores y tabulación automática en la consola del
  servidor

> **Advertencia:** Better Fabric Console adicionalmente requiere
> [adventure-platform-fabric](https://modrinth.com/mod/adventure-platform-mod)
> como dependencia. Sin él, el mod carga sin salida de colores.

### Técnico: Carpet + The Möbius Automata

Para entusiastas de redstone y técnica:

- **[Carpet](https://modrinth.com/mod/carpet)** — reglas de servidor
  adicionales, herramientas de depuración, ayudas de análisis de redstone
- **[The Möbius Automata](https://modrinth.com/mod/the-mbius-automata)** — un
  mod de bots construido sobre Carpet que automatiza la caza, construcción y
  minería de jugadores

### Explorador de recetas: JEI

[JEI (Just Enough Items)](https://modrinth.com/mod/jei) muestra todas las
recetas y usos de objetos directamente en el inventario — especialmente útil con
Farmer's Delight. Desde Minecraft 1.21.2, las recetas se sincronizan del lado
del servidor, por lo que JEI debe instalarse tanto en el **servidor como en el
cliente**.

### Análisis del servidor: Plan

[Plan | Player Analytics](https://modrinth.com/plugin/plan) proporciona un panel
web con estadísticas de tiempo de juego, historial de inicio de sesión y
tendencias de rendimiento del servidor. Accesible en tu red local en el puerto 8804.

## Instalación de mods en el cliente

A diferencia de los paquetes de recursos, los mods de Fabric **no se distribuyen
automáticamente** a los clientes. Cada mod que agregue nuevos bloques u objetos
debe **instalarse manualmente en cada cliente** en la versión exacta.

Usando el **Prism Launcher** esto es fácil: gestión de mods → buscar mod →
agregar versión compatible. La regla general:

- **Nuevos bloques/objetos** (ej. Farmer's Delight) → servidor **y** cliente
- **Generación de mundo o equilibrio** (ej. Terralith, Lithium) → solo servidor
- **Consola del servidor / análisis** (ej. Better Fabric Console, Plan) → solo servidor

Si falta un mod o la versión no coincide, el cliente muestra un mensaje de error
listando los mods faltantes al intentar conectarse.

## Actualización automática de mods

Con más de 20 mods, comprobar manualmente las actualizaciones se vuelve tedioso.
Escribí un script en bash `check-updates.sh` que compara todos los archivos
`.jar` en la carpeta `mods` contra la **API de Modrinth** usando hashes SHA1:

```bash
./check-updates.sh
```

El script muestra una vista general (comprobados / actualizados /
actualizaciones disponibles) y pregunta si las actualizaciones encontradas deben
instalarse directamente. Los archivos antiguos se respaldan con `mv`, y el
respaldo se elimina solo tras una descarga exitosa.

```bash
#!/bin/bash
cd "$(dirname "$0")/mods" || { echo "❌ ¡carpeta mods no encontrada!"; exit 1; }

# Recopilar hashes SHA1 de todos los jars
hashes=$(sha1sum *.jar | awk '{print "\""$1"\""}' | paste -sd, -)

response=$(curl -s -X POST "https://api.modrinth.com/v2/version_files/update" \
  -H "Content-Type: application/json" \
  -d "{\"loaders\":[\"fabric\"],\"game_versions\":[\"26.2\"],\"algorithm\":\"sha1\",\"hashes\":[$hashes]}")

total=0
outdated=0
up_to_date=0
not_found=0
outdated_files=()
outdated_targets=()
outdated_urls=()

for jarfile in *.jar; do
  total=$((total + 1))
  hash=$(sha1sum "$jarfile" | cut -d' ' -f1)

  latest_hashes=$(echo "$response" | jq -r --arg h "$hash" '.[$h].files[]?.hashes.sha1 // empty')

  if [ -z "$latest_hashes" ]; then
    not_found=$((not_found + 1))
    continue
  fi

  if grep -qx "$hash" <<< "$latest_hashes"; then
    up_to_date=$((up_to_date + 1))
  else
    outdated=$((outdated + 1))
    latest_file=$(echo "$response" | jq -r --arg h "$hash" '.[$h].files[0].filename // empty')
    latest_url=$(echo "$response" | jq -r --arg h "$hash" '.[$h].files[0].url // empty')
    echo "🔄 Actualización disponible: $jarfile -> $latest_file"
    outdated_files+=("$jarfile")
    outdated_targets+=("$latest_file")
    outdated_urls+=("$latest_url")
  fi
done

echo ""
echo "----------------------------------------"
echo "📦 Total de archivos comprobados: $total"
echo "✅ Actualizados:          $up_to_date"
echo "🔄 Actualizaciones disponibles:   $outdated"
echo "❓ No encontrados en Modrinth: $not_found"
echo "----------------------------------------"

if [ "$outdated" -eq 0 ]; then
  exit 0
fi

echo ""
read -p "¿Quieres actualizar estos $outdated mod(s) ahora? [y/N] " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Cancelado, no se hicieron cambios."
  exit 0
fi

echo ""
for i in "${!outdated_files[@]}"; do
  old="${outdated_files[$i]}"
  new="${outdated_targets[$i]}"
  url="${outdated_urls[$i]}"
  backup="${old}.bak"

  echo "➡  Actualizando $old -> $new"
  mv "$old" "$backup"

  if curl -sfL -o "$new" "$url"; then
    rm "$backup"
    echo "   ✅ Éxito, respaldo eliminado."
  else
    mv "$backup" "$old"
    echo "   ❌ Descarga fallida, restaurado archivo original."
  fi
done

echo ""
echo "Hecho."
```

> **Importante:** Detén el servidor antes de ejecutar el script — nunca
> reemplaces un archivo `.jar` mientras está cargado. El script requiere `jq`
> (`apt install jq`).

## Conclusión

Ejecutar un servidor Fabric junto a un servidor PaperMC es sencillo: directorio
separado, cargador de Fabric vía Meta API, API de Fabric como base, y luego
agregar mods a tu gusto. La configuración inicial toma menos de 30 minutos —
todo después es selección de mods y configuración.

Para mí, la mayor ganancia fue la combinación de Terralith (mundo visualmente
diverso) y los mods de Delight (agricultura y cocina relajada). Esto nos da un
servidor en el que toda la familia puede jugar — sin cambios agresivos en la
jugabilidad. En cuanto al servidor PaperMC, lo mantendré como respaldo por ahora
y eventualmente lo eliminaré.

Si tienes preguntas o ejecutas tu propio servidor Fabric: házmelo saber.
Agradezco comentarios y consejos para la configuración de mods.

Un saludo,  
Sebastian

{{< translation-note >}}
