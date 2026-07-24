# Descargar Nimbus

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  La pasarela MCP unificada para agentes de IA en producción. Un solo comando instala el CLI, la pasarela y todos los servidores MCP incluidos — verificado con SHA256, sin registro, se ejecuta localmente.
</p>

<div class="prereq-callout" markdown="1">

**Requisito previo:** Nimbus necesita <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a> (o <a href="https://orbstack.dev/" target="_blank">OrbStack</a> en Mac) instalado y **en ejecución** antes de instalar. La instalación es gratis y lleva un par de minutos.

**Comprobación rápida — ejecuta esto primero:**

```bash
docker ps
```

Si ves una tabla `CONTAINER ID` (o una fila "no containers"), Docker está arriba y todo listo. Si ves `Cannot connect to the Docker daemon`, inicia Docker Desktop (macOS / Windows) o `sudo systemctl start docker` (Linux) e inténtalo de nuevo.

</div>

## Instala para tu plataforma

=== "macOS"

    Apple Silicon e Intel. Requiere macOS 12 Monterey o posterior.

    **Instalar (última versión):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    El instalador detecta automáticamente Apple Silicon frente a Intel y verifica contra los SHA256SUMS publicados.

    Descargas directas:

    - [Apple Silicon (M1/M2/M3/M4) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Mac Intel →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    **Requisitos del sistema:**

    - **SO:** macOS 12 Monterey o posterior (Apple Silicon o Intel)
    - **Docker:** Docker Desktop 4.x+ o [OrbStack](https://orbstack.dev/) — el demonio debe estar en ejecución
    - **Python:** 3.12+ (se instala automáticamente con [`uv`](https://astral.sh/uv) si falta)
    - **Disco:** ~30 MB para el CLI, ~2 GB una vez que se descargan las imágenes Docker
    - **RAM:** 4 GB mínimo, 8 GB recomendado

    **Fija una versión específica:**

    Establece `NIMBUS_VERSION` en el lado derecho de la pipe (para que `curl` no la vea y la variable llegue al script instalado):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Linux"

    x86_64 y aarch64. Probado en Ubuntu 22.04+, Debian 12+, Fedora 39+ y Arch.

    **Instalar (última versión):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    Descargas directas:

    - [x86_64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)
    - [aarch64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-arm64.tar.gz)

    **Requisitos del sistema:**

    - **SO:** glibc 2.31+ (Ubuntu 22.04, Debian 12, Fedora 39, Arch)
    - **Docker:** Docker Desktop 4.x+, [OrbStack](https://orbstack.dev/), o un Docker Engine headless — el demonio debe estar en ejecución
    - **Python:** 3.12+ (se instala automáticamente con [`uv`](https://astral.sh/uv) si falta)
    - **Disco:** ~30 MB para el CLI, ~2 GB una vez que se descargan las imágenes Docker
    - **RAM:** 4 GB mínimo, 8 GB recomendado

    **Fija una versión específica:**

    Establece `NIMBUS_VERSION` en el lado derecho de la pipe (para que `curl` no la vea y la variable llegue al script instalado):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Windows"

    PowerShell y WSL2. No se requieren permisos de administrador. El instalador se encarga de configurar el PATH y registra Nimbus en tu perfil de usuario.

    **Instalar (última versión):**

    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

    Descargas directas:

    - [One-click: lanzador install.cmd →](https://nimbus.yoodule.com/install.cmd)
    - [Windows (x64) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    **Requisitos del sistema:**

    - **SO:** Windows 10 build 19041+ o Windows 11 con WSL2 habilitado
    - **Docker:** Docker Desktop 4.x+ (con backend WSL2) — el demonio debe estar en ejecución
    - **Python:** 3.12+ (se instala automáticamente con [`uv`](https://astral.sh/uv) si falta)
    - **Disco:** ~30 MB para el CLI, ~2 GB una vez que se descargan las imágenes Docker
    - **RAM:** 4 GB mínimo, 8 GB recomendado (Qdrant + Docker)

    **Fija una versión específica:**

    Establece `NIMBUS_VERSION` en tu shell antes de ejecutar el instalador (para que la variable llegue al script instalado):

    ```powershell
    $env:NIMBUS_VERSION = "v1.0.3"; irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

---

Explora todas las versiones publicadas en la [página de lanzamientos](https://github.com/Yoodule/nimbus/releases).

---

## Verifica antes de instalar

Cada lanzamiento se distribuye con un archivo `SHA256SUMS`. El instalador comprueba los checksums automáticamente. Para inspeccionar los checksums tú mismo, descarga el archivo desde la [página de lanzamientos](https://github.com/Yoodule/nimbus/releases) y ejecuta:

```bash
sha256sum -c --strict SHA256SUMS
```

Cada lanzamiento está atestiguado con SLSA por GitHub Actions. Puedes ver la atestación en la [página de lanzamientos](https://github.com/Yoodule/nimbus/releases).

---

## Actualizar

El CLI se actualiza a sí mismo en sitio. Tu `mcp.json`, `.env`, tokens de OAuth y el índice de Qdrant se conservan:

```bash
nimbus upgrade
```

Para actualizar a una versión específica:

```bash
nimbus upgrade --version v1.0.3
```

---

## Desinstalar

Elimina el CLI, la pasarela, la pila local de Docker y el directorio de instalación en un solo paso:

```bash
nimbus uninstall
```

Si quieres conservar tu configuración (mcp.json, .env, tokens) para una reinstalación futura, pasa `--keep-config`:

```bash
nimbus uninstall --keep-config
```

---

## Qué se instala

El instalador escribe todo bajo `~/.nimbus/` (o `$NIMBUS_HOME` si lo estableces):

```
~/.nimbus/
├── nimbus                # Shim del CLI
├── nimbus-gateway-*      # Binario compilado de la pasarela
├── mcp.json              # Registro de servidores
├── servers/              # Servidores MCP incluidos
├── .env                  # Configuración local (OPENROUTER_API_KEY, QDRANT_URL, …)
└── logs/                 # Logs de ejecución
```

También añade `export NIMBUS_HOME` y `PATH` a tu archivo de configuración del shell (`~/.zshrc`, `~/.bashrc` o `$PROFILE` en Windows) para que `nimbus` esté en tu PATH en nuevos shells.

---

## FAQ

### El instalador dice "arm64 not found" en mi Mac Apple Silicon.

Ese mensaje viene de un instalador antiguo. Ejecuta `nimbus upgrade` para obtener la última versión, o descarga una copia nueva del script directamente:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

El instalador actual sigue la redirección CDN de GitHub, detecta tu arquitectura y falla rápido con un error accionable si el activo falta de verdad.

### ¿Puedo instalar en una máquina sin Docker?

Sí. El CLI y la pasarela se ejecutan de forma nativa. La pila MCP incluida (navegador Playwright, Postgres para agentes, Qdrant) usa Docker, pero puedes omitirla con `nimbus start --no-deps` y apuntar Nimbus a servidores MCP remotos mediante `mcp.json`.

### ¿Cuánto pesa la descarga?

El tarball del CLI ocupa ~30 MB comprimido. Las imágenes Docker que se descargan en el primer arranque añaden otros ~2 GB (Qdrant, Playwright, Postgres). Si tienes poco ancho de banda, el modo de inicio `--no-deps` omite la descarga de Docker.

### ¿Dónde se guardan mis tokens de OAuth?

En memoria por defecto — reautoriza al reiniciar. Establece `NIMBUS_PERSIST_TOKENS=1` en `~/.nimbus/.env` para cifrarlos en reposo bajo `~/.nimbus/tokens/`.

### ¿Funciona en Apple Silicon bajo Rosetta?

Sí — establece `NIMBUS_HOST_ARCH=amd64` antes del comando de instalación para obtener la build Intel. No distribuimos un binario universal porque la tooling de gatekeeper añade más de 60 MB para un pequeño subconjunto de usuarios; Rosetta lo maneja de forma transparente.

### ¿Cómo ejecuto varias instancias de Nimbus en el mismo host? {#how-do-i-run-multiple-nimbus-instances-on-the-same-host}

Nimbus se vincula a puertos fijos del host (`3000`, `8088`, `6333`, `5433`, `6080`, `8006`, `8007`, `8081`), por lo que la instalación por defecto es de una sola instancia. Para ejecutar una segunda, clona el repositorio, reasigna puertos en `compose.yaml`, establece un `NIMBUS_HOME` único y configura `COMPOSE_PROJECT_NAME` para que las dos pilas no colisionen. Detalles completos en la [sección de instancias múltiples](#how-do-i-run-multiple-nimbus-instances-on-the-same-host) más abajo.

### La instalación se queda colgada o curl falla — ¿qué hago?

La causa más común es un proxy corporativo interceptando TLS. Establece `HTTPS_PROXY` e inténtalo de nuevo. Si el problema es específicamente el CDN, el script de instalación acepta `NIMBUS_VERSION` para fijar un lanzamiento conocido como bueno, y también puedes descargar el tarball directamente desde la [página de lanzamientos](https://github.com/Yoodule/nimbus/releases) y descomprimirlo a mano en `~/.nimbus/` — el binario es autocontenido.

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.05em; margin: 0 0 16px 0;">
    ¿Quieres una configuración guiada? Reserva una sesión de onboarding 1 a 1 y recorreremos juntos tu espacio de trabajo.
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    Reservar sesión de onboarding →
  </a>
</div>
