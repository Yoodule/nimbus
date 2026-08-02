# Solución de problemas

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Si <code>nimbus</code> no se comporta como esperas, empieza con <code>nimbus doctor</code>: imprime un panel de salud que cubre la accesibilidad de Docker, el desfase de versión CLI/gateway, la salud de los contenedores y si tu instalación está por detrás de la última versión. La mayoría de los problemas aparecen ahí.
</p>

Si `doctor` no cubre tu síntoma, las secciones siguientes están organizadas por **lo que estás viendo**, no por el componente que sospeches: elige la coincidencia más cercana.

---

## Empieza aquí: `nimbus doctor`

```bash
nimbus doctor
```

Comprueba cuatro cosas e imprime una línea por comprobación:

- **Sondeo de Docker** — ¿se puede alcanzar el daemon? Se ejecuta primero para que una máquina nueva no vea un muro de "todo bien" mientras `nimbus start` está a punto de fallar.
- **Desfase CLI / gateway** — ¿el contenedor del gateway en ejecución es más antiguo que tu CLI por más de una versión menor? Un CLI desfasado avisará pero no rechazará arrancar.
- **Salud de los contenedores** — ¿están sanos los contenedores del gateway, postgres, redis y qdrant?
- **Frescura de actualizaciones** — ¿hay un release más nuevo en GitHub? (Se omite en builds de desarrollo donde la clave pública de minisign está en blanco.)

El código de salida siempre es `0` — `doctor` nunca falla, muestra avisos para que siga siendo utilizable como comprobación de estado desde CI y monitorización.

---

## Problemas de instalación

### `nimbus` no está en mi `PATH` tras la instalación

El instalador escribe `export NIMBUS_HOME=~/.nimbus` y las actualizaciones de `PATH` en `~/.zshrc`, `~/.bashrc` o `$PROFILE` (Windows). Abre un nuevo shell o aplica el rc en el actual:

```bash
# macOS / Linux — elige el shell que realmente uses
source ~/.zshrc
source ~/.bashrc
```

Si `nimbus` sigue sin aparecer, la instalación puede haber fallado en silencio. Revisa el registro de instalación (la ruta se imprime al final de una ejecución correcta) y vuelve a ejecutar con el script explícito:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

### El instalador dice "arm64 not found" en Apple Silicon

Ese mensaje viene de un instalador obsoleto. Obtén una copia nueva del script y vuelve a ejecutar:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

El instalador actual sigue la redirección CDN de GitHub, detecta tu arquitectura mediante `uname -m` y falla rápido con un error accionable si el activo falta de verdad.

### La instalación se cuelga o `curl` falla

La causa más común es un proxy corporativo interceptando TLS:

```bash
HTTPS_PROXY=http://tu-proxy:puerto curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

Si el problema es específicamente el CDN, fija una versión conocida con `NIMBUS_VERSION`:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.2 bash
```

También puedes descargar el tarball directamente desde la [página de releases](https://github.com/Yoodule/nimbus/releases) y descomprimirlo a mano en `~/.nimbus/` — el binario es autocontenido.

### La instalación termina pero `nimbus start` dice que Docker no es accesible

Docker está instalado pero el daemon no está corriendo. Arranca:

- **macOS / Windows** — abre Docker Desktop (u OrbStack). El icono de la ballena en la barra de menús debe estar sólido, no animado.
- **Linux** — `sudo systemctl start docker`, o `sudo dockerd` si no usas systemd.

Verifica con `docker ps`. Si ves `Cannot connect to the Docker daemon`, el daemon aún no está listo: espera unos segundos y vuelve a intentarlo.

---

## Problemas de contenedores

### Un contenedor se reinicia continuamente

`docker ps` muestra un contenedor en estado `Restarting`. La causa más común es un volumen obsoleto de un `.env` antiguo:

```bash
docker logs nimbus-gateway-1 --tail 100    # o nimbus-postgres-1 / nimbus-redis-1 / nimbus-qdrant-1
```

Busca el error concreto. Si es un fallo de autenticación de Postgres o Redis, tu `.env` rotó las credenciales pero el volumen con nombre aún tiene las antiguas. Recuperación:

```bash
nimbus stop
# Mueve el volumen obsoleto a un lado para que la inicialización se ejecute
# de nuevo. nimbus start autogenera credenciales nuevas sobre un volumen
# fresco; el antiguo se conserva como -corrupt-<timestamp> por si necesitas
# inspeccionarlo.
docker volume rm nimbus_postgres_data
nimbus start
```

Los antiguos subcomandos `nimbus recover-pg-role` / `nimbus recover-redis-password` ya no existen — este flujo es el camino de recuperación soportado.

### `nimbus start` dice "port already in use"

Nimbus vincula puertos fijos del host (3000 dashboard, 8088 gateway, 6080 noVNC, 5433 postgres, 6379 redis, 6333/6334 qdrant). Si algo más en el host ya ocupa uno de esos puertos, `start` fallará indicando el número en conflicto.

Encuentra y detén el proceso en conflicto:

```bash
# macOS / Linux
sudo lsof -iTCP:8088 -sTCP:LISTEN
```

Para una configuración multiinstancia a largo plazo, consulta la sección **Múltiples instancias** en la [página de descarga](download.md#how-do-i-run-multiple-nimbus-instances-on-the-same-host).

### El dashboard dice "gateway unreachable"

El dashboard se ejecuta en `http://localhost:3000`. Si carga pero cada acción devuelve "gateway unreachable", el contenedor del gateway no está escuchando en 8088. Comprueba:

```bash
docker ps | grep gateway
docker logs nimbus-gateway-1 --tail 50
curl -s http://localhost:8088/version
```

Una causa común en Apple Silicon bajo Rosetta es un desajuste de plataforma — la imagen del gateway es `linux/arm64` pero el runtime pide `amd64`. Establece `NIMBUS_HOST_ARCH=arm64` antes de `nimbus start`.

---

## Problemas de OAuth

### "OAuth callback failed" al hacer clic en Approve

El gateway intenta aterrizar el callback de OAuth en `http://localhost:8088/oauth/callback` por defecto. Si estás ejecutando Nimbus tras un túnel o navegador remoto, el proveedor rechazará el callback porque la URL no coincide con la registrada.

La solución es fijar `NIMBUS_URL` (usado por el proxy OAuth del dashboard) y `OAUTH_REDIRECT_BASE` (usado por el gateway) a la URL pública a la que el proveedor debe redirigir. Ambos están documentados en [`.env.example`](https://github.com/Yoodule/nimbus/blob/main/.env.example).

### Upwork OAuth: "redirect_uri_mismatch"

El proveedor OAuth de Upwork es estricto con la coincidencia exacta de `redirect_uri`. El `UPWORK_REDIRECT_URI` del instalador debe ser idéntico al registrado en la consola de desarrollador de Upwork — carácter por carácter, incluida la barra final.

Si ves `redirect_uri_mismatch`, comprueba el valor en `~/.nimbus/.env`:

```bash
nimbus config get UPWORK_REDIRECT_URI
```

…y compáralo byte a byte con la consola de Upwork. Tras corregirlo, reinicia el contenedor del gateway:

```bash
nimbus stop && nimbus start
```

### Los tokens desaparecen tras reiniciar

Es por diseño. Por defecto, los tokens OAuth viven solo en memoria — cada reinicio es una reautorización nueva. Es el valor por defecto más seguro para hosts compartidos / multiusuario.

---

## Problemas de servidores MCP

### Un servidor MCP incluido no arranca

`docker logs nimbus-gateway-1 --tail 200` mostrará el subproceso stdio muriendo con un error de import o una variable de entorno faltante. Los dos culpables habituales:

1. **Falta una API key** — comprueba `~/.nimbus/.env` para los `*_API_KEYS` relevantes (plural, separados por comas). El gateway y el dashboard leen la forma plural y recurren a la singular; pool vacío ⇒ el proveedor devuelve 401.
2. **Desfase de versión de Python** — los servidores MCP incluidos se ejecutan vía `uv run python`. Si tienes un Python de sistema anterior a 3.12, `uv` obtendrá uno más reciente en la primera invocación, lo que puede tardar unos 30 segundos la primera vez.

### `find_tools` no devuelve nada

`find_tools` es búsqueda semántica sobre el índice vectorial de Qdrant. Resultados vacíos significan que:

- Qdrant no es accesible — `docker ps | grep qdrant` debe mostrar sano; `curl http://localhost:6333/healthz` debe devolver 200.
- El índice aún no se ha construido — el gateway ingiere descripciones de herramientas en el primer arranque. Espera un minuto y vuelve a intentar. Si sigue vacío tras 5 minutos, reinicia: `nimbus stop && nimbus start`.

### Añadí un servidor a `mcp.json` pero no aparece

Dos posibilidades:

1. **Error de sintaxis en `mcp.json`** — el gateway omite silenciosamente las entradas malformadas. Valida con:
   ```bash
   nimbus mcp list
   ```
   Si tu servidor nuevo no está en la lista, el problema es el JSON. Una coma sobrante o una barra invertida sin escapar suele ser el culpable.

2. **El gateway no se ha recargado** — `mcp.json` se lee al iniciar el contenedor. Tras editar:
   ```bash
   nimbus stop && nimbus start
   ```

Para servidores HTTP, la URL debe ser accesible desde dentro del contenedor del gateway — `localhost` desde tu máquina anfitriona *no* es el mismo `localhost` dentro de Docker. Usa `host.docker.internal:<puerto>` en su lugar.

---

## Problemas con OpenRouter / modelos

### "Invalid API key" en el primer chat

El CLI pide `OPENROUTER_API_KEY` en el primer `nimbus start` y lo escribe en `~/.nimbus/.env`. Si te saltaste ese prompt o la clave está obsoleta:

```bash
nimbus config set OPENROUTER_API_KEYS sk-or-v1-...
nimbus stop && nimbus start
```

Nota el plural: `OPENROUTER_API_KEYS` (separadas por comas para múltiples claves, con fallback a la forma singular). Un pool de claves vacío o incorrecto hace que cada petición salga sin cabecera `Authorization` y el proveedor devuelva 401.

### "Model not found" para un ID de modelo concreto

Nimbus usa por defecto `openrouter/free`. Si pasas `--model <id>` y el modelo no existe en OpenRouter, obtendrás un 404. Verifica el ID del modelo en [openrouter.ai/models](https://openrouter.ai/models) — cambian con frecuencia.

Para modelos Ollama, el prefijo de enrutamiento es `ollama/<nombre-del-modelo>` (por ejemplo `ollama/llama3.1`). Los IDs sin prefijo se asumen como OpenRouter.

### Fallos de embeddings

Las embeddings usan por defecto `nvidia/llama-nemotron-embed-vl-1b-v2:free` (2048-dim, tier gratuito). Si ese modelo no está disponible o está limitado por tasa, establece un fallback:

```bash
nimbus config set EMBEDDING_MODEL openai/text-embedding-3-small
nimbus stop && nimbus start
```

Esto reingerirá cada descripción de herramienta en Qdrant en el siguiente arranque — espera un minuto de indexación en caché fría.

---

## Recuperación

### "Nimbus was installed by a different version"

Significa que una instalación previa dejó un volumen de Postgres o Redis congelado bajo credenciales que ya no coinciden con tu `.env`. La solución:

```bash
nimbus stop && nimbus start
```

`start` autodetecta el desajuste y reinicializa el rol/contraseña contra el `.env` actual. Los antiguos subcomandos `recover-pg-role` / `recover-redis-password` ya no existen.

### Borrar todo y empezar de cero

```bash
nimbus uninstall
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

Esto elimina el CLI, todos los contenedores, todos los volúmenes con nombre y `~/.nimbus/`. Perderás los tokens OAuth, `.env` y cualquier descripción de herramienta almacenada en Qdrant. Reautoriza en el primer arranque.

### Quiero volver a una versión anterior del CLI

```bash
nimbus update --version v1.0.1
```

(O la versión que necesites.) El self-update del CLI usa el mismo reemplazo atómico + SHA256 + minisign que `nimbus update`, simplemente fijado a un release concreto.

---

## ¿Sigues atascado?

Abre un issue en el [tracker de Nimbus](https://github.com/Yoodule/nimbus/issues) con:

- Salida de `nimbus doctor`
- Plataforma y arquitectura del host (`uname -a` en macOS/Linux, `systeminfo` en Windows)
- Registros de contenedores relevantes: `docker logs nimbus-gateway-1 --tail 200` (o `nimbus-postgres-1` / `nimbus-redis-1` / `nimbus-qdrant-1`)
- Cualquier cosa de `~/.nimbus/logs/` que parezca relacionada

El CLI nunca envía tu `.env` ni los tokens OAuth — esos te corresponden a ti censurar, pero el resto de diagnósticos es seguro de compartir.